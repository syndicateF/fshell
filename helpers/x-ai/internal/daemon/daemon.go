// Package daemon implements the main x-ai daemon lifecycle.
// This is the central coordinator for all AI chatbot functionality.
package daemon

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"sync"
	"syscall"
	"time"
)

// Config holds daemon configuration
type Config struct {
	// Socket path for IPC
	SocketPath string `json:"socket_path"`

	// Data directory for SQLite and cache
	DataDir string `json:"data_dir"`

	// Idle timeout - daemon exits after this duration of inactivity
	IdleTimeout time.Duration `json:"idle_timeout"`

	// Heartbeat interval for keep-alive
	HeartbeatInterval time.Duration `json:"heartbeat_interval"`

	// OpenAI configuration
	OpenAI OpenAIConfig `json:"openai"`

	// Ollama configuration (for future local mode)
	Ollama OllamaConfig `json:"ollama"`
}

// OpenAIConfig holds OpenAI-specific settings
type OpenAIConfig struct {
	// API key - loaded from environment or config
	APIKey string `json:"api_key"`

	// Default model to use
	Model string `json:"model"`

	// Max tokens for response
	MaxTokens int `json:"max_tokens"`

	// Request timeout
	Timeout time.Duration `json:"timeout"`

	// Base URL (for proxies or Azure)
	BaseURL string `json:"base_url,omitempty"`
}

// OllamaConfig holds Ollama-specific settings
type OllamaConfig struct {
	// Ollama API endpoint
	Endpoint string `json:"endpoint"`

	// Default model
	Model string `json:"model"`

	// Request timeout
	Timeout time.Duration `json:"timeout"`
}

// DefaultConfig returns sensible defaults
func DefaultConfig() *Config {
	homeDir, _ := os.UserHomeDir()
	dataDir := filepath.Join(homeDir, ".local", "share", "x-ai")

	return &Config{
		SocketPath:        "/tmp/x-ai.sock",
		DataDir:           dataDir,
		IdleTimeout:       30 * time.Minute,
		HeartbeatInterval: 15 * time.Second,
		OpenAI: OpenAIConfig{
			APIKey:    os.Getenv("OPENAI_API_KEY"),
			Model:     "gpt-4o-mini", // Cost-effective default
			MaxTokens: 4096,
			Timeout:   60 * time.Second,
		},
		Ollama: OllamaConfig{
			Endpoint: "http://localhost:11434",
			Model:    "llama3.2:3b",
			Timeout:  120 * time.Second,
		},
	}
}

// LoadConfig loads configuration from file, falling back to defaults
func LoadConfig(path string) (*Config, error) {
	cfg := DefaultConfig()

	// If config file exists, merge it
	if path != "" {
		data, err := os.ReadFile(path)
		if err != nil {
			if !os.IsNotExist(err) {
				return nil, fmt.Errorf("read config: %w", err)
			}
			// File doesn't exist, use defaults
		} else {
			if err := json.Unmarshal(data, cfg); err != nil {
				return nil, fmt.Errorf("parse config: %w", err)
			}
		}
	}

	// Environment variables override config file
	if key := os.Getenv("OPENAI_API_KEY"); key != "" {
		cfg.OpenAI.APIKey = key
	}
	if socket := os.Getenv("X_AI_SOCKET"); socket != "" {
		cfg.SocketPath = socket
	}
	if dataDir := os.Getenv("X_AI_DATA_DIR"); dataDir != "" {
		cfg.DataDir = dataDir
	}

	return cfg, nil
}

// Daemon is the main x-ai daemon
type Daemon struct {
	cfg    *Config
	ctx    context.Context
	cancel context.CancelFunc

	// IPC server (will be added)
	// ipc *ipc.Server

	// Providers (will be added)
	// openai *providers.OpenAIProvider

	// Conversation manager (will be added)
	// convMgr *conversation.Manager

	// Activity tracking for idle timeout
	lastActivity time.Time
	activityMu   sync.Mutex

	// Shutdown coordination
	wg sync.WaitGroup
}

// New creates a new daemon instance
func New(cfg *Config) (*Daemon, error) {
	if cfg == nil {
		cfg = DefaultConfig()
	}

	// Ensure data directory exists
	if err := os.MkdirAll(cfg.DataDir, 0755); err != nil {
		return nil, fmt.Errorf("create data dir: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &Daemon{
		cfg:          cfg,
		ctx:          ctx,
		cancel:       cancel,
		lastActivity: time.Now(),
	}, nil
}

// Run starts the daemon and blocks until shutdown
func (d *Daemon) Run() error {
	log.Printf("x-ai daemon starting...")
	log.Printf("  Socket: %s", d.cfg.SocketPath)
	log.Printf("  Data dir: %s", d.cfg.DataDir)
	log.Printf("  Idle timeout: %s", d.cfg.IdleTimeout)

	// Validate configuration
	if err := d.validate(); err != nil {
		return fmt.Errorf("config validation: %w", err)
	}

	// Setup signal handling
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	// Start idle timeout watcher
	d.wg.Add(1)
	go d.idleWatcher()

	// Start heartbeat (placeholder - will send to IPC clients)
	d.wg.Add(1)
	go d.heartbeat()

	// TODO: Initialize components
	// - IPC server
	// - OpenAI provider
	// - Conversation manager
	// - SQLite store

	log.Printf("x-ai daemon ready")

	// Wait for shutdown signal
	select {
	case sig := <-sigCh:
		log.Printf("Received signal: %s, shutting down...", sig)
	case <-d.ctx.Done():
		log.Printf("Context cancelled, shutting down...")
	}

	return d.shutdown()
}

// validate checks configuration validity
func (d *Daemon) validate() error {
	if d.cfg.OpenAI.APIKey == "" {
		log.Printf("WARNING: OPENAI_API_KEY not set, online mode will not work")
	}
	return nil
}

// idleWatcher monitors for inactivity and triggers shutdown
func (d *Daemon) idleWatcher() {
	defer d.wg.Done()

	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-d.ctx.Done():
			return
		case <-ticker.C:
			d.activityMu.Lock()
			idle := time.Since(d.lastActivity)
			d.activityMu.Unlock()

			if idle > d.cfg.IdleTimeout {
				log.Printf("Idle timeout reached (%s), initiating shutdown", idle)
				d.cancel()
				return
			}
		}
	}
}

// heartbeat sends periodic heartbeats to connected clients
func (d *Daemon) heartbeat() {
	defer d.wg.Done()

	ticker := time.NewTicker(d.cfg.HeartbeatInterval)
	defer ticker.Stop()

	for {
		select {
		case <-d.ctx.Done():
			return
		case <-ticker.C:
			// TODO: Send heartbeat to IPC clients
			// d.ipc.Broadcast(HeartbeatMessage{...})
		}
	}
}

// RecordActivity updates the last activity timestamp
func (d *Daemon) RecordActivity() {
	d.activityMu.Lock()
	d.lastActivity = time.Now()
	d.activityMu.Unlock()
}

// shutdown gracefully stops all components
func (d *Daemon) shutdown() error {
	log.Printf("Initiating graceful shutdown...")

	// Cancel context to stop all goroutines
	d.cancel()

	// Wait for goroutines with timeout
	done := make(chan struct{})
	go func() {
		d.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		log.Printf("Graceful shutdown complete")
	case <-time.After(10 * time.Second):
		log.Printf("Shutdown timeout, forcing exit")
	}

	// TODO: Cleanup
	// - Close IPC socket
	// - Close database connections
	// - Save any pending state

	return nil
}

// Status returns current daemon status
type Status struct {
	Running       bool          `json:"running"`
	Uptime        time.Duration `json:"uptime"`
	IdleTime      time.Duration `json:"idle_time"`
	Provider      string        `json:"provider"`
	Model         string        `json:"model"`
	Conversations int           `json:"conversations"`
}

// GetStatus returns current daemon status
func (d *Daemon) GetStatus() Status {
	d.activityMu.Lock()
	idleTime := time.Since(d.lastActivity)
	d.activityMu.Unlock()

	return Status{
		Running:  true,
		IdleTime: idleTime,
		Provider: "openai", // TODO: Get from active provider
		Model:    d.cfg.OpenAI.Model,
	}
}
