// Package providers defines the interface for AI providers and implements OpenAI.
package providers

import (
	"context"
)

// Provider is the interface all AI providers must implement
type Provider interface {
	// Name returns the provider identifier
	Name() string

	// Chat sends a message and returns a response
	// For streaming, use the stream callback
	Chat(ctx context.Context, req *ChatRequest, stream StreamCallback) (*ChatResponse, error)

	// ValidateConnection checks if the provider is reachable
	ValidateConnection(ctx context.Context) error

	// ListModels returns available models
	ListModels(ctx context.Context) ([]Model, error)
}

// StreamCallback is called for each chunk of a streaming response
type StreamCallback func(chunk *StreamChunk) error

// StreamChunk represents a piece of a streaming response
type StreamChunk struct {
	Content string // Delta text content
	Done    bool   // True if stream is complete
}

// ChatRequest contains the input for a chat completion
type ChatRequest struct {
	// Messages is the conversation history
	Messages []Message

	// Model to use (provider-specific)
	Model string

	// MaxTokens limits response length
	MaxTokens int

	// Temperature controls randomness (0-1)
	Temperature float64

	// SystemPrompt is prepended to messages
	SystemPrompt string
}

// ChatResponse contains the result of a chat completion
type ChatResponse struct {
	// Content is the full response text
	Content string

	// Model that was used
	Model string

	// TokensUsed for tracking
	TokensUsed TokenUsage

	// FinishReason indicates why generation stopped
	FinishReason string
}

// TokenUsage tracks token consumption
type TokenUsage struct {
	Prompt     int `json:"prompt"`
	Completion int `json:"completion"`
	Total      int `json:"total"`
}

// Message represents a single message in conversation
type Message struct {
	Role    string `json:"role"`    // "system", "user", "assistant"
	Content string `json:"content"` // Message text
}

// Model represents an available AI model
type Model struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	MaxTokens   int    `json:"max_tokens,omitempty"`
}

// ProviderError wraps provider-specific errors with context
type ProviderError struct {
	Provider  string
	Code      string
	Message   string
	Retryable bool
	Original  error
}

func (e *ProviderError) Error() string {
	return e.Provider + ": " + e.Message
}

func (e *ProviderError) Unwrap() error {
	return e.Original
}

// Common error codes
const (
	ErrCodeRateLimit         = "RATE_LIMIT"
	ErrCodeAuth              = "AUTH_ERROR"
	ErrCodeNetwork           = "NETWORK_ERROR"
	ErrCodeServer            = "SERVER_ERROR"
	ErrCodeInvalidReq        = "INVALID_REQUEST"
	ErrCodeContextLen        = "CONTEXT_LENGTH"
	ErrCodeTimeout           = "TIMEOUT"
	ErrCodeModelNotAvailable = "MODEL_NOT_AVAILABLE"
)
