// Package providers - Google Gemini implementation
package providers

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"google.golang.org/genai"
)

// GeminiProvider implements the Provider interface for Google Gemini API
type GeminiProvider struct {
	client    *genai.Client
	model     string
	maxTokens int
	timeout   time.Duration
}

// GeminiConfig holds configuration for Gemini provider
type GeminiConfig struct {
	APIKey    string
	Model     string
	MaxTokens int
	Timeout   time.Duration
}

// NewGeminiProvider creates a new Gemini provider
func NewGeminiProvider(ctx context.Context, cfg GeminiConfig) (*GeminiProvider, error) {
	if cfg.APIKey == "" {
		return nil, &ProviderError{
			Provider:  "gemini",
			Code:      ErrCodeAuth,
			Message:   "API key is required",
			Retryable: false,
		}
	}

	// Default values
	if cfg.Model == "" {
		cfg.Model = "gemini-2.5-flash"
	}
	if cfg.MaxTokens == 0 {
		cfg.MaxTokens = 4096
	}
	if cfg.Timeout == 0 {
		cfg.Timeout = 60 * time.Second
	}

	// Create client with API key
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  cfg.APIKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return nil, &ProviderError{
			Provider:  "gemini",
			Code:      ErrCodeNetwork,
			Message:   fmt.Sprintf("failed to create client: %v", err),
			Retryable: true,
			Original:  err,
		}
	}

	return &GeminiProvider{
		client:    client,
		model:     cfg.Model,
		maxTokens: cfg.MaxTokens,
		timeout:   cfg.Timeout,
	}, nil
}

// Name returns the provider identifier
func (p *GeminiProvider) Name() string {
	return "gemini"
}

// Chat sends a message and streams the response
func (p *GeminiProvider) Chat(ctx context.Context, req *ChatRequest, stream StreamCallback) (*ChatResponse, error) {
	// Create timeout context
	ctx, cancel := context.WithTimeout(ctx, p.timeout)
	defer cancel()

	// Build contents from message history
	contents := make([]*genai.Content, 0, len(req.Messages))
	for _, msg := range req.Messages {
		role := genai.RoleUser
		if msg.Role == "assistant" || msg.Role == "model" {
			role = genai.RoleModel
		}
		// Skip system messages - they go in config
		if msg.Role == "system" {
			continue
		}

		contents = append(contents, &genai.Content{
			Parts: []*genai.Part{{Text: msg.Content}},
			Role:  role,
		})
	}

	// Determine model
	model := req.Model
	if model == "" {
		model = p.model
	}

	// Determine max tokens
	maxTokens := req.MaxTokens
	if maxTokens == 0 {
		maxTokens = p.maxTokens
	}

	// Build config
	config := &genai.GenerateContentConfig{
		MaxOutputTokens: int32(maxTokens),
	}

	// Add system instruction if provided
	if req.SystemPrompt != "" {
		config.SystemInstruction = &genai.Content{
			Parts: []*genai.Part{{Text: req.SystemPrompt}},
		}
	}

	// Set temperature if specified
	if req.Temperature > 0 {
		temp := float32(req.Temperature)
		config.Temperature = &temp
	}

	// Use non-streaming for reliability, then simulate stream callback
	result, err := p.client.Models.GenerateContent(ctx, model, contents, config)
	if err != nil {
		return nil, p.wrapError(err)
	}

	// Extract content from result
	var fullContent strings.Builder
	var finishReason string

	if result != nil && len(result.Candidates) > 0 {
		candidate := result.Candidates[0]

		// Get finish reason
		if candidate.FinishReason != "" {
			finishReason = string(candidate.FinishReason)
		}

		// Get text from parts
		if candidate.Content != nil && len(candidate.Content.Parts) > 0 {
			for _, part := range candidate.Content.Parts {
				if part.Text != "" {
					fullContent.WriteString(part.Text)

					// Send to stream callback
					if stream != nil {
						if err := stream(&StreamChunk{
							Content: part.Text,
							Done:    false,
						}); err != nil {
							return nil, fmt.Errorf("stream callback: %w", err)
						}
					}
				}
			}
		}
	}

	// Send final chunk
	if stream != nil {
		if err := stream(&StreamChunk{
			Done: true,
		}); err != nil {
			return nil, fmt.Errorf("stream callback: %w", err)
		}
	}

	// Check if we got any content
	if fullContent.Len() == 0 {
		return nil, &ProviderError{
			Provider:  "gemini",
			Code:      ErrCodeServer,
			Message:   "No response content received",
			Retryable: true,
		}
	}

	return &ChatResponse{
		Content:      fullContent.String(),
		Model:        model,
		FinishReason: finishReason,
	}, nil
}

// ValidateConnection checks if Gemini is reachable
func (p *GeminiProvider) ValidateConnection(ctx context.Context) error {
	// Simple test - generate a tiny response
	_, err := p.client.Models.GenerateContent(ctx, p.model, genai.Text("hi"), &genai.GenerateContentConfig{
		MaxOutputTokens: 1,
	})
	if err != nil {
		return p.wrapError(err)
	}
	return nil
}

// ListModels returns available Gemini models
func (p *GeminiProvider) ListModels(ctx context.Context) ([]Model, error) {
	// Return commonly used Gemini models
	// The API list is complex to paginate, so we use known models
	return []Model{
		{ID: "gemini-2.5-flash", Name: "Gemini 2.5 Flash"},
		{ID: "gemini-2.5-pro", Name: "Gemini 2.5 Pro"},
		{ID: "gemini-2.0-flash", Name: "Gemini 2.0 Flash"},
		{ID: "gemini-1.5-flash", Name: "Gemini 1.5 Flash"},
		{ID: "gemini-1.5-pro", Name: "Gemini 1.5 Pro"},
	}, nil
}

// wrapError converts Gemini errors to ProviderError
func (p *GeminiProvider) wrapError(err error) error {
	if err == nil {
		return nil
	}

	pe := &ProviderError{
		Provider: "gemini",
		Original: err,
	}

	// Check for API errors
	var apiErr *genai.APIError
	if errors.As(err, &apiErr) {
		switch apiErr.Code {
		case 401, 403:
			pe.Code = ErrCodeAuth
			pe.Message = "Invalid API key"
			pe.Retryable = false
		case 429:
			pe.Code = ErrCodeRateLimit
			pe.Message = "Rate limit exceeded"
			pe.Retryable = true
		case 500, 502, 503:
			pe.Code = ErrCodeServer
			pe.Message = "Gemini server error"
			pe.Retryable = true
		case 400:
			pe.Code = ErrCodeInvalidReq
			pe.Message = apiErr.Message
			pe.Retryable = false
		default:
			pe.Code = ErrCodeServer
			pe.Message = apiErr.Message
			pe.Retryable = apiErr.Code >= 500
		}
		return pe
	}

	// Check for context cancellation
	if errors.Is(err, context.Canceled) {
		pe.Code = "CANCELLED"
		pe.Message = "Request cancelled"
		pe.Retryable = false
		return pe
	}

	// Check for timeout
	if errors.Is(err, context.DeadlineExceeded) {
		pe.Code = ErrCodeTimeout
		pe.Message = "Request timed out"
		pe.Retryable = true
		return pe
	}

	// Generic error
	pe.Code = ErrCodeNetwork
	pe.Message = err.Error()
	pe.Retryable = true
	return pe
}

// SetModel changes the default model
func (p *GeminiProvider) SetModel(model string) {
	p.model = model
}

// GetModel returns the current model
func (p *GeminiProvider) GetModel() string {
	return p.model
}
