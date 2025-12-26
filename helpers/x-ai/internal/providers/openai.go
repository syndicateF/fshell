// Package providers - OpenAI ChatGPT implementation
package providers

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	openai "github.com/sashabaranov/go-openai"
)

// OpenAIProvider implements the Provider interface for OpenAI API
type OpenAIProvider struct {
	client    *openai.Client
	model     string
	maxTokens int
	timeout   time.Duration
}

// OpenAIConfig holds configuration for OpenAI provider
type OpenAIConfig struct {
	APIKey    string
	Model     string
	MaxTokens int
	Timeout   time.Duration
	BaseURL   string // Optional, for proxies
}

// NewOpenAIProvider creates a new OpenAI provider
func NewOpenAIProvider(cfg OpenAIConfig) (*OpenAIProvider, error) {
	if cfg.APIKey == "" {
		return nil, &ProviderError{
			Provider:  "openai",
			Code:      ErrCodeAuth,
			Message:   "API key is required",
			Retryable: false,
		}
	}

	// Default values
	if cfg.Model == "" {
		cfg.Model = "gpt-4o-mini"
	}
	if cfg.MaxTokens == 0 {
		cfg.MaxTokens = 4096
	}
	if cfg.Timeout == 0 {
		cfg.Timeout = 60 * time.Second
	}

	// Create client config
	clientCfg := openai.DefaultConfig(cfg.APIKey)
	if cfg.BaseURL != "" {
		clientCfg.BaseURL = cfg.BaseURL
	}

	// Set custom HTTP client with timeout
	clientCfg.HTTPClient = &http.Client{
		Timeout: cfg.Timeout,
	}

	client := openai.NewClientWithConfig(clientCfg)

	return &OpenAIProvider{
		client:    client,
		model:     cfg.Model,
		maxTokens: cfg.MaxTokens,
		timeout:   cfg.Timeout,
	}, nil
}

// Name returns the provider identifier
func (p *OpenAIProvider) Name() string {
	return "openai"
}

// Chat sends a message and streams the response
func (p *OpenAIProvider) Chat(ctx context.Context, req *ChatRequest, stream StreamCallback) (*ChatResponse, error) {
	// Build messages array
	messages := make([]openai.ChatCompletionMessage, 0, len(req.Messages)+1)

	// Add system prompt if present
	if req.SystemPrompt != "" {
		messages = append(messages, openai.ChatCompletionMessage{
			Role:    openai.ChatMessageRoleSystem,
			Content: req.SystemPrompt,
		})
	}

	// Add conversation messages
	for _, msg := range req.Messages {
		messages = append(messages, openai.ChatCompletionMessage{
			Role:    msg.Role,
			Content: msg.Content,
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

	// Determine temperature
	temperature := req.Temperature
	if temperature == 0 {
		temperature = 0.7 // Default creativity
	}

	// Create streaming request
	streamReq := openai.ChatCompletionRequest{
		Model:       model,
		Messages:    messages,
		MaxTokens:   maxTokens,
		Temperature: float32(temperature),
		Stream:      true,
	}

	// Start streaming
	streamResp, err := p.client.CreateChatCompletionStream(ctx, streamReq)
	if err != nil {
		return nil, p.wrapError(err)
	}
	defer streamResp.Close()

	// Collect full response while streaming
	var fullContent strings.Builder
	var finishReason string

	for {
		chunk, err := streamResp.Recv()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break // Stream complete
			}
			return nil, p.wrapError(err)
		}

		// Extract content delta
		if len(chunk.Choices) > 0 {
			delta := chunk.Choices[0].Delta.Content
			if delta != "" {
				fullContent.WriteString(delta)

				// Stream to callback
				if stream != nil {
					if err := stream(&StreamChunk{
						Content: delta,
						Done:    false,
					}); err != nil {
						return nil, fmt.Errorf("stream callback: %w", err)
					}
				}
			}

			// Check finish reason
			if chunk.Choices[0].FinishReason != "" {
				finishReason = string(chunk.Choices[0].FinishReason)
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

	return &ChatResponse{
		Content:      fullContent.String(),
		Model:        model,
		FinishReason: finishReason,
		// Note: Token usage not available in streaming mode
	}, nil
}

// ValidateConnection checks if OpenAI is reachable
func (p *OpenAIProvider) ValidateConnection(ctx context.Context) error {
	// List models as a simple connectivity check
	_, err := p.client.ListModels(ctx)
	if err != nil {
		return p.wrapError(err)
	}
	return nil
}

// ListModels returns available OpenAI models
func (p *OpenAIProvider) ListModels(ctx context.Context) ([]Model, error) {
	resp, err := p.client.ListModels(ctx)
	if err != nil {
		return nil, p.wrapError(err)
	}

	// Filter to chat models only
	chatModels := []string{
		"gpt-4o",
		"gpt-4o-mini",
		"gpt-4-turbo",
		"gpt-4",
		"gpt-3.5-turbo",
	}

	models := make([]Model, 0)
	modelSet := make(map[string]bool)
	for _, m := range chatModels {
		modelSet[m] = true
	}

	for _, m := range resp.Models {
		if modelSet[m.ID] {
			models = append(models, Model{
				ID:   m.ID,
				Name: m.ID,
			})
		}
	}

	return models, nil
}

// wrapError converts OpenAI errors to ProviderError
func (p *OpenAIProvider) wrapError(err error) error {
	if err == nil {
		return nil
	}

	// Check for API errors
	var apiErr *openai.APIError
	if errors.As(err, &apiErr) {
		pe := &ProviderError{
			Provider: "openai",
			Original: err,
		}

		switch apiErr.HTTPStatusCode {
		case 401:
			pe.Code = ErrCodeAuth
			pe.Message = "Invalid API key"
			pe.Retryable = false
		case 429:
			pe.Code = ErrCodeRateLimit
			pe.Message = "Rate limit exceeded"
			pe.Retryable = true
		case 500, 502, 503:
			pe.Code = ErrCodeServer
			pe.Message = "OpenAI server error"
			pe.Retryable = true
		case 400:
			// Check for context length error
			if strings.Contains(apiErr.Message, "context_length") ||
				strings.Contains(apiErr.Message, "maximum context length") {
				pe.Code = ErrCodeContextLen
				pe.Message = "Context length exceeded"
				pe.Retryable = false
			} else {
				pe.Code = ErrCodeInvalidReq
				pe.Message = apiErr.Message
				pe.Retryable = false
			}
		default:
			pe.Code = ErrCodeServer
			pe.Message = apiErr.Message
			pe.Retryable = apiErr.HTTPStatusCode >= 500
		}

		return pe
	}

	// Check for context cancellation
	if errors.Is(err, context.Canceled) {
		return &ProviderError{
			Provider:  "openai",
			Code:      "CANCELLED",
			Message:   "Request cancelled",
			Retryable: false,
			Original:  err,
		}
	}

	// Check for timeout
	if errors.Is(err, context.DeadlineExceeded) {
		return &ProviderError{
			Provider:  "openai",
			Code:      ErrCodeTimeout,
			Message:   "Request timed out",
			Retryable: true,
			Original:  err,
		}
	}

	// Generic network error
	return &ProviderError{
		Provider:  "openai",
		Code:      ErrCodeNetwork,
		Message:   err.Error(),
		Retryable: true,
		Original:  err,
	}
}

// SetModel changes the default model
func (p *OpenAIProvider) SetModel(model string) {
	p.model = model
}

// GetModel returns the current model
func (p *OpenAIProvider) GetModel() string {
	return p.model
}
