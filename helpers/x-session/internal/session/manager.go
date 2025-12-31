// Package session provides the core session manager for power actions
package session

import (
	"context"
	"errors"
	"log/slog"
	"sync"

	"x-session/internal/hooks"
	"x-session/internal/logind"
)

var (
	ErrAlreadyPending = errors.New("action already pending")
	ErrNoPending      = errors.New("no pending action")
)

// ActionType represents the type of power action
type ActionType string

const (
	ActionShutdown  ActionType = "shutdown"
	ActionReboot    ActionType = "reboot"
	ActionSuspend   ActionType = "suspend"
	ActionHibernate ActionType = "hibernate"
)

// ServiceIdentity is the name used for inhibitors (centralized, not hardcoded)
const ServiceIdentity = "x-session"

// Manager handles session power actions
type Manager struct {
	logind     *logind.Client
	hookConfig *hooks.Config

	mu               sync.Mutex
	pendingAction    ActionType
	pendingForce     bool
	pendingInhibitor *logind.InhibitorLock
	cancelFn         context.CancelFunc

	// Signal callbacks (set by D-Bus service)
	OnHookStarted       func(name string)
	OnHookCompleted     func(name string)
	OnShutdownProceed   func()
	OnShutdownCancelled func()
}

// New creates a new session manager
func New(logindClient *logind.Client, hookConfig *hooks.Config) *Manager {
	return &Manager{
		logind:     logindClient,
		hookConfig: hookConfig,
	}
}

// IsPending returns true if an action is pending
func (m *Manager) IsPending() bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.pendingAction != ""
}

// RequestShutdown initiates a shutdown request
// Returns immediately - async semantics
// accepted = request received, NOT action completed
func (m *Manager) RequestShutdown(force bool) (bool, error) {
	return m.requestAction(ActionShutdown, force)
}

// RequestReboot initiates a reboot request
func (m *Manager) RequestReboot(force bool) (bool, error) {
	return m.requestAction(ActionReboot, force)
}

// RequestSuspend initiates a suspend request
func (m *Manager) RequestSuspend() error {
	// Suspend is immediate, no hooks needed
	return m.logind.Suspend(false)
}

// RequestHibernate initiates a hibernate request
func (m *Manager) RequestHibernate() error {
	// Hibernate is immediate, no hooks needed
	return m.logind.Hibernate(false)
}

// CancelPending cancels a pending shutdown/reboot
func (m *Manager) CancelPending() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.pendingAction == "" {
		return ErrNoPending
	}

	slog.Info("Cancelling pending action", "action", m.pendingAction)

	// Cancel context (stops hooks if running)
	if m.cancelFn != nil {
		m.cancelFn()
		m.cancelFn = nil
	}

	// Release inhibitor
	if m.pendingInhibitor != nil {
		m.pendingInhibitor.Release()
		m.pendingInhibitor = nil
	}

	m.pendingAction = ""
	m.pendingForce = false

	// Emit signal
	if m.OnShutdownCancelled != nil {
		m.OnShutdownCancelled()
	}

	return nil
}

// requestAction is the common path for shutdown/reboot
func (m *Manager) requestAction(action ActionType, force bool) (bool, error) {
	m.mu.Lock()
	if m.pendingAction != "" {
		m.mu.Unlock()
		return false, ErrAlreadyPending
	}

	// Take delay inhibitor using ServiceIdentity
	inhibitor, err := m.logind.TakeInhibitor(
		string(action),
		ServiceIdentity,
		"Pre-shutdown cleanup",
		"delay",
	)
	if err != nil {
		m.mu.Unlock()
		return false, err
	}

	m.pendingAction = action
	m.pendingForce = force
	m.pendingInhibitor = inhibitor
	m.mu.Unlock()

	// Linux-grade: proceed directly, trust systemd to handle apps gracefully
	go m.executeAction()
	return true, nil
}

// ProceedWithAction executes the pending action (called after user confirms blockers)
func (m *Manager) ProceedWithAction() error {
	m.mu.Lock()
	if m.pendingAction == "" {
		m.mu.Unlock()
		return ErrNoPending
	}
	m.mu.Unlock()

	go m.executeAction()
	return nil
}

// executeAction runs hooks and performs the power action
func (m *Manager) executeAction() {
	m.mu.Lock()
	action := m.pendingAction
	inhibitor := m.pendingInhibitor
	m.mu.Unlock()

	if action == "" {
		return
	}

	// Create context with timeout for hooks (configurable via hooks.yaml)
	ctx, cancel := context.WithTimeout(context.Background(), m.hookConfig.GlobalTimeout)
	m.mu.Lock()
	m.cancelFn = cancel
	m.mu.Unlock()
	defer cancel()

	// Emit proceed signal
	if m.OnShutdownProceed != nil {
		m.OnShutdownProceed()
	}

	// Run hooks
	for _, hook := range m.hookConfig.GetEnabledHooks() {
		if ctx.Err() != nil {
			slog.Warn("Hook execution cancelled", "hook", hook.Name)
			break
		}

		slog.Info("Running hook", "name", hook.Name)
		if m.OnHookStarted != nil {
			m.OnHookStarted(hook.Name)
		}

		hookCtx, hookCancel := context.WithTimeout(ctx, hook.Timeout)
		err := hook.Run(hookCtx)
		hookCancel()

		if err != nil {
			if errors.Is(err, context.DeadlineExceeded) {
				slog.Warn("Hook timed out", "hook", hook.Name)
			} else {
				slog.Warn("Hook failed", "hook", hook.Name, "error", err)
			}
			// Continue anyway - don't block shutdown for hook failure
		}

		if m.OnHookCompleted != nil {
			m.OnHookCompleted(hook.Name)
		}
	}

	// Release inhibitor BEFORE calling logind
	m.mu.Lock()
	if inhibitor != nil {
		inhibitor.Release()
		m.pendingInhibitor = nil
	}
	m.pendingAction = ""
	m.cancelFn = nil
	m.mu.Unlock()

	// Execute power action
	slog.Info("Executing power action", "action", action)
	var err error
	switch action {
	case ActionShutdown:
		err = m.logind.PowerOff(false)
	case ActionReboot:
		err = m.logind.Reboot(false)
	}

	if err != nil {
		slog.Error("Power action failed", "action", action, "error", err)
	}
}
