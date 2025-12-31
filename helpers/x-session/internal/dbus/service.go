// Package dbus provides the D-Bus service for x-session
package dbus

import (
	"log/slog"

	"github.com/godbus/dbus/v5"
	"github.com/godbus/dbus/v5/introspect"

	"x-session/internal/session"
)

const (
	serviceName = "org.xshell.Session"
	objectPath  = "/org/xshell/Session"
	ifaceName   = "org.xshell.Session"
)

// Service wraps the D-Bus connection and exports the session interface
type Service struct {
	conn    *dbus.Conn
	manager *session.Manager
}

// NewService creates and registers the D-Bus service on user bus
func NewService(manager *session.Manager) (*Service, error) {
	conn, err := dbus.SessionBus()
	if err != nil {
		return nil, err
	}

	s := &Service{
		conn:    conn,
		manager: manager,
	}

	// Wire up signal callbacks
	manager.OnHookStarted = s.emitHookStarted
	manager.OnHookCompleted = s.emitHookCompleted
	manager.OnShutdownProceed = s.emitShutdownProceed
	manager.OnShutdownCancelled = s.emitShutdownCancelled

	// Export the service
	err = conn.Export(s, objectPath, ifaceName)
	if err != nil {
		conn.Close()
		return nil, err
	}

	// Export introspection
	introNode := &introspect.Node{
		Name: objectPath,
		Interfaces: []introspect.Interface{
			introspect.IntrospectData,
			{
				Name: ifaceName,
				Methods: []introspect.Method{
					{Name: "RequestShutdown", Args: []introspect.Arg{
						{Name: "force", Type: "b", Direction: "in"},
						{Name: "accepted", Type: "b", Direction: "out"},
					}},
					{Name: "RequestReboot", Args: []introspect.Arg{
						{Name: "force", Type: "b", Direction: "in"},
						{Name: "accepted", Type: "b", Direction: "out"},
					}},
					{Name: "RequestSuspend"},
					{Name: "RequestHibernate"},
					{Name: "CancelPending"},
					{Name: "ProceedWithAction"},
				},
				Signals: []introspect.Signal{
					{Name: "HookStarted", Args: []introspect.Arg{{Name: "name", Type: "s"}}},
					{Name: "HookCompleted", Args: []introspect.Arg{{Name: "name", Type: "s"}}},
					{Name: "ShutdownProceed"},
					{Name: "ShutdownCancelled"},
				},
				Properties: []introspect.Property{
					{Name: "ShutdownPending", Type: "b", Access: "read"},
				},
			},
		},
	}
	err = conn.Export(introspect.NewIntrospectable(introNode), objectPath, "org.freedesktop.DBus.Introspectable")
	if err != nil {
		conn.Close()
		return nil, err
	}

	// Export properties interface
	err = conn.Export(s, objectPath, "org.freedesktop.DBus.Properties")
	if err != nil {
		conn.Close()
		return nil, err
	}

	// Request name
	reply, err := conn.RequestName(serviceName, dbus.NameFlagDoNotQueue)
	if err != nil {
		conn.Close()
		return nil, err
	}
	if reply != dbus.RequestNameReplyPrimaryOwner {
		conn.Close()
		return nil, err
	}

	return s, nil
}

// Close releases the D-Bus connection
func (s *Service) Close() error {
	return s.conn.Close()
}

// D-Bus method implementations

// RequestShutdown handles shutdown requests
func (s *Service) RequestShutdown(force bool) (bool, *dbus.Error) {
	accepted, err := s.manager.RequestShutdown(force)
	if err != nil {
		slog.Error("RequestShutdown failed", "error", err)
		return false, dbus.MakeFailedError(err)
	}
	return accepted, nil
}

// RequestReboot handles reboot requests
func (s *Service) RequestReboot(force bool) (bool, *dbus.Error) {
	accepted, err := s.manager.RequestReboot(force)
	if err != nil {
		slog.Error("RequestReboot failed", "error", err)
		return false, dbus.MakeFailedError(err)
	}
	return accepted, nil
}

// RequestSuspend handles suspend requests
func (s *Service) RequestSuspend() *dbus.Error {
	if err := s.manager.RequestSuspend(); err != nil {
		return dbus.MakeFailedError(err)
	}
	return nil
}

// RequestHibernate handles hibernate requests
func (s *Service) RequestHibernate() *dbus.Error {
	if err := s.manager.RequestHibernate(); err != nil {
		return dbus.MakeFailedError(err)
	}
	return nil
}

// CancelPending cancels a pending action
func (s *Service) CancelPending() *dbus.Error {
	if err := s.manager.CancelPending(); err != nil {
		return dbus.MakeFailedError(err)
	}
	return nil
}

// ProceedWithAction proceeds with pending action after user confirms blockers
func (s *Service) ProceedWithAction() *dbus.Error {
	if err := s.manager.ProceedWithAction(); err != nil {
		return dbus.MakeFailedError(err)
	}
	return nil
}

// ShutdownPending property getter
func (s *Service) Get(iface, prop string) (dbus.Variant, *dbus.Error) {
	if iface != ifaceName {
		return dbus.Variant{}, nil
	}
	switch prop {
	case "ShutdownPending":
		return dbus.MakeVariant(s.manager.IsPending()), nil
	}
	return dbus.Variant{}, nil
}

// Signal emitters

func (s *Service) emitHookStarted(name string) {
	s.conn.Emit(objectPath, ifaceName+".HookStarted", name)
}

func (s *Service) emitHookCompleted(name string) {
	s.conn.Emit(objectPath, ifaceName+".HookCompleted", name)
}

func (s *Service) emitShutdownProceed() {
	s.conn.Emit(objectPath, ifaceName+".ShutdownProceed")
}

func (s *Service) emitShutdownCancelled() {
	s.conn.Emit(objectPath, ifaceName+".ShutdownCancelled")
}
