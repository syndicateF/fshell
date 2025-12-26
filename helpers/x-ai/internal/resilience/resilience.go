// Package resilience implements retry logic and circuit breaker patterns.
package resilience

import (
	"context"
	"errors"
	"log"
	"math/rand"
	"sync"
	"time"
)

// RetryConfig configures the retry behavior
type RetryConfig struct {
	// MaxRetries is the maximum number of retry attempts
	MaxRetries int

	// InitialDelay is the first retry delay
	InitialDelay time.Duration

	// MaxDelay caps the exponential backoff
	MaxDelay time.Duration

	// BackoffFactor multiplies delay each retry
	BackoffFactor float64

	// JitterFactor adds randomness (0-1)
	JitterFactor float64
}

// DefaultRetryConfig returns sensible retry defaults
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxRetries:    3,
		InitialDelay:  time.Second,
		MaxDelay:      30 * time.Second,
		BackoffFactor: 2.0,
		JitterFactor:  0.1,
	}
}

// RetryableFunc is a function that can be retried
type RetryableFunc func(ctx context.Context) error

// IsRetryable checks if an error is worth retrying
type IsRetryable func(err error) bool

// Retry executes a function with exponential backoff
func Retry(ctx context.Context, cfg RetryConfig, fn RetryableFunc, isRetryable IsRetryable) error {
	var lastErr error
	delay := cfg.InitialDelay

	for attempt := 0; attempt <= cfg.MaxRetries; attempt++ {
		// Check context first
		if err := ctx.Err(); err != nil {
			return err
		}

		// Execute the function
		err := fn(ctx)
		if err == nil {
			return nil // Success
		}

		lastErr = err

		// Check if we should retry
		if !isRetryable(err) {
			log.Printf("Non-retryable error (attempt %d/%d): %v", attempt+1, cfg.MaxRetries+1, err)
			return err
		}

		// Last attempt, don't wait
		if attempt == cfg.MaxRetries {
			break
		}

		log.Printf("Retryable error (attempt %d/%d): %v, retrying in %v",
			attempt+1, cfg.MaxRetries+1, err, delay)

		// Wait with jitter
		jitteredDelay := addJitter(delay, cfg.JitterFactor)
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(jitteredDelay):
		}

		// Exponential backoff
		delay = time.Duration(float64(delay) * cfg.BackoffFactor)
		if delay > cfg.MaxDelay {
			delay = cfg.MaxDelay
		}
	}

	return lastErr
}

// addJitter adds random variation to a duration
func addJitter(d time.Duration, factor float64) time.Duration {
	if factor <= 0 {
		return d
	}
	jitter := float64(d) * factor * (rand.Float64()*2 - 1) // ±factor
	return time.Duration(float64(d) + jitter)
}

// CircuitState represents the circuit breaker state
type CircuitState int

const (
	CircuitClosed   CircuitState = iota // Normal operation
	CircuitOpen                         // Blocking requests
	CircuitHalfOpen                     // Testing recovery
)

func (s CircuitState) String() string {
	switch s {
	case CircuitClosed:
		return "closed"
	case CircuitOpen:
		return "open"
	case CircuitHalfOpen:
		return "half-open"
	default:
		return "unknown"
	}
}

// CircuitBreakerConfig configures the circuit breaker
type CircuitBreakerConfig struct {
	// FailureThreshold opens circuit after this many failures
	FailureThreshold int

	// RecoveryTimeout is how long to wait before testing recovery
	RecoveryTimeout time.Duration

	// HalfOpenSuccesses required to close circuit
	HalfOpenSuccesses int
}

// DefaultCircuitBreakerConfig returns sensible defaults
func DefaultCircuitBreakerConfig() CircuitBreakerConfig {
	return CircuitBreakerConfig{
		FailureThreshold:  5,
		RecoveryTimeout:   30 * time.Second,
		HalfOpenSuccesses: 2,
	}
}

// CircuitBreaker implements the circuit breaker pattern
type CircuitBreaker struct {
	cfg           CircuitBreakerConfig
	state         CircuitState
	failures      int
	successes     int
	lastFailure   time.Time
	mu            sync.RWMutex
	onStateChange func(from, to CircuitState)
}

// NewCircuitBreaker creates a new circuit breaker
func NewCircuitBreaker(cfg CircuitBreakerConfig) *CircuitBreaker {
	return &CircuitBreaker{
		cfg:   cfg,
		state: CircuitClosed,
	}
}

// OnStateChange sets a callback for state transitions
func (cb *CircuitBreaker) OnStateChange(fn func(from, to CircuitState)) {
	cb.mu.Lock()
	cb.onStateChange = fn
	cb.mu.Unlock()
}

// State returns the current circuit state
func (cb *CircuitBreaker) State() CircuitState {
	cb.mu.RLock()
	defer cb.mu.RUnlock()
	return cb.state
}

// Execute runs a function through the circuit breaker
func (cb *CircuitBreaker) Execute(ctx context.Context, fn func(context.Context) error) error {
	// Check if we should allow the request
	if !cb.allowRequest() {
		return ErrCircuitOpen
	}

	// Execute the function
	err := fn(ctx)

	// Record result
	if err != nil {
		cb.recordFailure()
	} else {
		cb.recordSuccess()
	}

	return err
}

// allowRequest checks if a request should be allowed
func (cb *CircuitBreaker) allowRequest() bool {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	switch cb.state {
	case CircuitClosed:
		return true

	case CircuitOpen:
		// Check if recovery timeout has passed
		if time.Since(cb.lastFailure) > cb.cfg.RecoveryTimeout {
			cb.setState(CircuitHalfOpen)
			return true
		}
		return false

	case CircuitHalfOpen:
		return true

	default:
		return false
	}
}

// recordSuccess records a successful call
func (cb *CircuitBreaker) recordSuccess() {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	switch cb.state {
	case CircuitHalfOpen:
		cb.successes++
		if cb.successes >= cb.cfg.HalfOpenSuccesses {
			cb.setState(CircuitClosed)
		}
	case CircuitClosed:
		cb.failures = 0 // Reset failure count on success
	}
}

// recordFailure records a failed call
func (cb *CircuitBreaker) recordFailure() {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	cb.failures++
	cb.lastFailure = time.Now()

	switch cb.state {
	case CircuitClosed:
		if cb.failures >= cb.cfg.FailureThreshold {
			cb.setState(CircuitOpen)
		}
	case CircuitHalfOpen:
		cb.setState(CircuitOpen)
	}
}

// setState changes the circuit state
func (cb *CircuitBreaker) setState(newState CircuitState) {
	if cb.state == newState {
		return
	}

	oldState := cb.state
	cb.state = newState
	cb.failures = 0
	cb.successes = 0

	log.Printf("Circuit breaker: %s -> %s", oldState, newState)

	if cb.onStateChange != nil {
		go cb.onStateChange(oldState, newState)
	}
}

// Reset manually resets the circuit breaker
func (cb *CircuitBreaker) Reset() {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.setState(CircuitClosed)
}

// ErrCircuitOpen is returned when the circuit is open
var ErrCircuitOpen = errors.New("circuit breaker is open")

// ResilientExecutor combines retry and circuit breaker
type ResilientExecutor struct {
	retry   RetryConfig
	circuit *CircuitBreaker
}

// NewResilientExecutor creates a new resilient executor
func NewResilientExecutor(retry RetryConfig, circuit *CircuitBreaker) *ResilientExecutor {
	return &ResilientExecutor{
		retry:   retry,
		circuit: circuit,
	}
}

// Execute runs a function with retry and circuit breaker
func (re *ResilientExecutor) Execute(ctx context.Context, fn RetryableFunc, isRetryable IsRetryable) error {
	return re.circuit.Execute(ctx, func(ctx context.Context) error {
		return Retry(ctx, re.retry, fn, isRetryable)
	})
}
