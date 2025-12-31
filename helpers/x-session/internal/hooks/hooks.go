// Package hooks provides pre-shutdown hook configuration and execution
package hooks

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"gopkg.in/yaml.v3"
)

// Hook represents a pre-shutdown hook
type Hook struct {
	Name    string        `yaml:"name"`
	Enabled bool          `yaml:"enabled"`
	Timeout time.Duration `yaml:"timeout"`
	Command []string      `yaml:"command"`
}

// Config holds hook configuration
type Config struct {
	// GlobalTimeout is the maximum time for all hooks (default: 30s)
	GlobalTimeout time.Duration `yaml:"global_timeout"`
	Hooks         []Hook        `yaml:"hooks"`
}

// DefaultGlobalTimeout is used when not specified in config
const DefaultGlobalTimeout = 30 * time.Second

// EmptyConfig returns an empty hook configuration
// No default hooks - user must configure via ~/.config/x-session/hooks.yaml
func EmptyConfig() *Config {
	return &Config{
		GlobalTimeout: DefaultGlobalTimeout,
		Hooks:         nil,
	}
}

// LoadConfig loads hook configuration from user config
func LoadConfig() (*Config, error) {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return nil, err
	}

	configPath := filepath.Join(configDir, "x-session", "hooks.yaml")
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	// Set default timeout if not specified in YAML
	if config.GlobalTimeout == 0 {
		config.GlobalTimeout = DefaultGlobalTimeout
	}

	return &config, nil
}

// GetEnabledHooks returns only enabled hooks
func (c *Config) GetEnabledHooks() []Hook {
	var enabled []Hook
	for _, h := range c.Hooks {
		if h.Enabled {
			enabled = append(enabled, h)
		}
	}
	return enabled
}

// Run executes the hook with context timeout
func (h *Hook) Run(ctx context.Context) error {
	if len(h.Command) == 0 {
		return nil
	}

	cmd := exec.CommandContext(ctx, h.Command[0], h.Command[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}
