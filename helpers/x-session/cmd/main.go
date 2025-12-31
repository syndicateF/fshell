// x-session - Session management daemon for x-shell
//
// User D-Bus service for power action orchestration:
// - Pre-shutdown hooks (Docker, VMs cleanup)
// - Blocker detection
// - Inhibitor management via logind
// - Graceful shutdown coordination

package main

import (
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"x-session/internal/dbus"
	"x-session/internal/hooks"
	"x-session/internal/logind"
	"x-session/internal/session"
)

func main() {
	// Initialize structured logging
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	slog.Info("x-session starting...")

	// Initialize logind client (talks to system bus)
	logindClient, err := logind.New()
	if err != nil {
		slog.Error("Failed to connect to logind", "error", err)
		os.Exit(1)
	}
	defer logindClient.Close()

	// Load hook configuration
	hookConfig, err := hooks.LoadConfig()
	if err != nil {
		slog.Warn("No hook config found, running without hooks", "path", "~/.config/x-session/hooks.yaml")
		hookConfig = hooks.EmptyConfig()
	}

	// Create session manager
	manager := session.New(logindClient, hookConfig)

	// Start D-Bus service (user bus)
	service, err := dbus.NewService(manager)
	if err != nil {
		slog.Error("Failed to start D-Bus service", "error", err)
		os.Exit(1)
	}
	defer service.Close()

	slog.Info("x-session ready",
		"bus", "session",
		"name", "org.xshell.Session",
		"path", "/org/xshell/Session",
	)

	// Wait for shutdown signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	slog.Info("x-session shutting down...")
}
