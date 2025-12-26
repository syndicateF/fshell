// Package security implements input sanitization and validation.
package security

import (
	"regexp"
	"strings"
	"unicode"
)

// Sanitizer handles input sanitization
type Sanitizer struct {
	maxInputLength int
	maxLineCount   int
}

// Warning represents a sanitization warning
type Warning struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

// SanitizeResult contains the sanitized input and any warnings
type SanitizeResult struct {
	Input    string    `json:"input"`
	Warnings []Warning `json:"warnings,omitempty"`
}

// NewSanitizer creates a new sanitizer with defaults
func NewSanitizer() *Sanitizer {
	return &Sanitizer{
		maxInputLength: 100000, // 100k chars
		maxLineCount:   10000,
	}
}

// Sanitize cleans user input
func (s *Sanitizer) Sanitize(input string) SanitizeResult {
	result := SanitizeResult{
		Input:    input,
		Warnings: []Warning{},
	}

	// 1. Length check
	if len(input) > s.maxInputLength {
		result.Input = input[:s.maxInputLength]
		result.Warnings = append(result.Warnings, Warning{
			Type:    "truncated",
			Message: "Input was truncated to maximum length",
		})
	}

	// 2. Strip dangerous control characters (keep newlines, tabs)
	result.Input = s.stripControlChars(result.Input)

	// 3. Normalize line endings
	result.Input = strings.ReplaceAll(result.Input, "\r\n", "\n")
	result.Input = strings.ReplaceAll(result.Input, "\r", "\n")

	// 4. Check line count
	lines := strings.Split(result.Input, "\n")
	if len(lines) > s.maxLineCount {
		result.Input = strings.Join(lines[:s.maxLineCount], "\n")
		result.Warnings = append(result.Warnings, Warning{
			Type:    "lines_truncated",
			Message: "Input was truncated to maximum line count",
		})
	}

	// 5. Detect potential issues (warn only, don't block)
	if s.detectsSensitiveData(result.Input) {
		result.Warnings = append(result.Warnings, Warning{
			Type:    "sensitive_data",
			Message: "Input may contain sensitive information (credit card, SSN pattern detected)",
		})
	}

	if s.detectsInjectionPattern(result.Input) {
		result.Warnings = append(result.Warnings, Warning{
			Type:    "potential_injection",
			Message: "Input contains patterns similar to prompt injection attempts",
		})
	}

	return result
}

// stripControlChars removes dangerous control characters
func (s *Sanitizer) stripControlChars(input string) string {
	return strings.Map(func(r rune) rune {
		// Keep printable characters, newlines, and tabs
		if unicode.IsPrint(r) || r == '\n' || r == '\t' {
			return r
		}
		// Remove other control characters
		return -1
	}, input)
}

// Credit card pattern (simplified - 13-19 digits, optionally with dashes/spaces)
var creditCardPattern = regexp.MustCompile(`\b(?:\d[ -]*?){13,19}\b`)

// SSN pattern (XXX-XX-XXXX)
var ssnPattern = regexp.MustCompile(`\b\d{3}[-]?\d{2}[-]?\d{4}\b`)

// detectsSensitiveData looks for potentially sensitive information
func (s *Sanitizer) detectsSensitiveData(input string) bool {
	// Credit card pattern
	if creditCardPattern.MatchString(input) {
		return true
	}

	// SSN pattern
	if ssnPattern.MatchString(input) {
		return true
	}

	return false
}

// Common injection patterns
var injectionPatterns = []string{
	"ignore previous instructions",
	"ignore all previous",
	"disregard previous",
	"forget your instructions",
	"you are now",
	"system prompt",
	"reveal your prompt",
	"show me your instructions",
	"what are your instructions",
	"developer mode",
	"jailbreak",
	"DAN mode",
}

// detectsInjectionPattern checks for known prompt injection patterns
func (s *Sanitizer) detectsInjectionPattern(input string) bool {
	lower := strings.ToLower(input)

	for _, pattern := range injectionPatterns {
		if strings.Contains(lower, pattern) {
			return true
		}
	}

	return false
}

// ValidateAPIKey performs basic validation on an API key
func ValidateAPIKey(key string) bool {
	// OpenAI keys start with "sk-"
	if !strings.HasPrefix(key, "sk-") {
		return false
	}

	// Minimum reasonable length
	if len(key) < 20 {
		return false
	}

	return true
}
