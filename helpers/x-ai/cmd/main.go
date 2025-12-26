// x-ai is the AI chatbot daemon for x-shell.
// It handles all AI logic, keeping QML as pure UI.
//
// Usage:
//
//	x-ai daemon    Start the daemon (normally via systemd)
//	x-ai status    Check daemon status
//	x-ai --help    Show help
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"time"

	"x-ai/internal/conversation"
	"x-ai/internal/daemon"
	"x-ai/internal/ipc"
	"x-ai/internal/providers"
	"x-ai/internal/security"
)

func main() {
	log.SetFlags(log.Ltime | log.Lshortfile)

	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "daemon":
		runDaemon()
	case "status":
		checkStatus()
	case "test":
		runTest()
	case "-h", "--help", "help":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`x-ai - AI Chatbot Daemon for x-shell

Usage:
  x-ai daemon     Start the daemon
  x-ai status     Check daemon status
  x-ai test       Run a quick test
  x-ai --help     Show this help

Environment:
  OPENAI_API_KEY  OpenAI API key (required for online mode)
  X_AI_SOCKET     Socket path (default: /tmp/x-ai.sock)
  X_AI_DATA_DIR   Data directory (default: ~/.local/share/x-ai)`)
}

func runDaemon() {
	// Load configuration
	cfg, err := daemon.LoadConfig("")
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Create handler for IPC messages
	handler := &Handler{cfg: cfg}

	// Try to initialize a provider (Gemini first since it has free tier, then OpenAI)
	ctx := context.Background()

	// Try Gemini first (free tier available!)
	geminiKey := os.Getenv("GOOGLE_API_KEY")
	if geminiKey != "" {
		provider, err := providers.NewGeminiProvider(ctx, providers.GeminiConfig{
			APIKey:    geminiKey,
			Model:     "gemini-2.5-flash",
			MaxTokens: 4096,
			Timeout:   60 * time.Second,
		})
		if err != nil {
			log.Printf("Warning: Failed to initialize Gemini provider: %v", err)
		} else {
			handler.provider = provider
			log.Printf("Gemini provider initialized (model: gemini-2.5-flash)")
		}
	}

	// Fallback to OpenAI if no provider yet and key is available
	if handler.provider == nil && cfg.OpenAI.APIKey != "" {
		provider, err := providers.NewOpenAIProvider(providers.OpenAIConfig{
			APIKey:    cfg.OpenAI.APIKey,
			Model:     cfg.OpenAI.Model,
			MaxTokens: cfg.OpenAI.MaxTokens,
			Timeout:   cfg.OpenAI.Timeout,
		})
		if err != nil {
			log.Printf("Warning: Failed to initialize OpenAI provider: %v", err)
		} else {
			handler.provider = provider
			log.Printf("OpenAI provider initialized (model: %s)", cfg.OpenAI.Model)
		}
	}

	if handler.provider == nil {
		log.Printf("Warning: No AI provider available. Set GOOGLE_API_KEY or OPENAI_API_KEY")
	}

	// Initialize conversation manager
	convMgr, err := conversation.NewManager(conversation.ManagerConfig{
		DataDir: cfg.DataDir,
	}, handler.provider)
	if err != nil {
		log.Fatalf("Failed to initialize conversation manager: %v", err)
	}
	handler.convMgr = convMgr
	defer convMgr.Close()

	// Create IPC server
	ipcServer, err := ipc.NewServer(cfg.SocketPath, handler)
	if err != nil {
		log.Fatalf("Failed to create IPC server: %v", err)
	}
	handler.ipcServer = ipcServer

	// Set stream callback
	convMgr.SetStreamCallback(func(convID, msgID, content string, done bool) {
		msg, _ := ipc.NewMessage(ipc.TypeChatChunk, ipc.ChatChunkPayload{
			ConversationID: convID,
			MessageID:      msgID,
			Content:        content,
			Done:           done,
		})
		ipcServer.Broadcast(msg)
	})

	// Start IPC server
	ipcServer.Start()
	defer ipcServer.Stop()

	// Create and run daemon
	d, err := daemon.New(cfg)
	if err != nil {
		log.Fatalf("Failed to create daemon: %v", err)
	}

	if err := d.Run(); err != nil {
		log.Fatalf("Daemon error: %v", err)
	}
}

// Handler implements ipc.MessageHandler
type Handler struct {
	cfg       *daemon.Config
	provider  providers.Provider
	convMgr   *conversation.Manager
	ipcServer *ipc.Server
	sanitizer *security.Sanitizer
}

// HandleMessage processes incoming IPC messages
func (h *Handler) HandleMessage(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	log.Printf("IPC message: %s (id: %s)", msg.Type, msg.RequestID)

	// Lazy init sanitizer
	if h.sanitizer == nil {
		h.sanitizer = security.NewSanitizer()
	}

	switch msg.Type {
	case ipc.TypeChat:
		return h.handleChat(ctx, client, msg)
	case ipc.TypeNewConv:
		return h.handleNewConv(ctx, client, msg)
	case ipc.TypeLoadConv:
		return h.handleLoadConv(ctx, client, msg)
	case ipc.TypeListConvs:
		return h.handleListConvs(ctx, client, msg)
	case ipc.TypeDeleteConv:
		return h.handleDeleteConv(ctx, client, msg)
	case ipc.TypeStatus:
		return h.handleStatus(ctx, client, msg)
	default:
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInvalidReq,
			fmt.Sprintf("Unknown message type: %s", msg.Type), false)
	}
}

func (h *Handler) handleChat(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	var payload ipc.ChatPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInvalidReq, "Invalid payload", false)
	}

	// Check provider
	if h.provider == nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeAuthFailed,
			"No AI provider available. Check OPENAI_API_KEY.", false)
	}

	// Sanitize input
	result := h.sanitizer.Sanitize(payload.Content)
	if len(result.Warnings) > 0 {
		for _, w := range result.Warnings {
			log.Printf("Sanitization warning: %s - %s", w.Type, w.Message)
		}
	}

	// Create conversation if not specified
	convID := payload.ConversationID
	if convID == "" {
		conv, err := h.convMgr.NewConversation("")
		if err != nil {
			return h.sendError(client, msg.RequestID, ipc.ErrCodeInternal, err.Error(), false)
		}
		convID = conv.ID
	}

	// Send acknowledgment
	ack, _ := msg.Response(ipc.TypeAck, map[string]string{"conversation_id": convID})
	client.Send(ack)

	// Process chat (streaming handled by callback)
	_, err := h.convMgr.Chat(ctx, convID, result.Input)
	if err != nil {
		// Determine error type
		code := ipc.ErrCodeInternal
		retryable := false

		if pe, ok := err.(*providers.ProviderError); ok {
			switch pe.Code {
			case providers.ErrCodeRateLimit:
				code = ipc.ErrCodeRateLimit
				retryable = true
			case providers.ErrCodeAuth:
				code = ipc.ErrCodeAuthFailed
			case providers.ErrCodeNetwork:
				code = ipc.ErrCodeNetworkErr
				retryable = true
			case providers.ErrCodeServer:
				code = ipc.ErrCodeServerDown
				retryable = true
			case providers.ErrCodeContextLen:
				code = ipc.ErrCodeTokenLimit
			}
		}

		return h.sendError(client, msg.RequestID, code, err.Error(), retryable)
	}

	// Complete message sent via stream callback
	return nil
}

func (h *Handler) handleNewConv(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	var payload struct {
		Title string `json:"title"`
	}
	json.Unmarshal(msg.Payload, &payload)

	conv, err := h.convMgr.NewConversation(payload.Title)
	if err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInternal, err.Error(), false)
	}

	resp, _ := msg.Response(ipc.TypeConvData, conv)
	client.Send(resp)
	return nil
}

func (h *Handler) handleLoadConv(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	var payload ipc.ConversationPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInvalidReq, "Invalid payload", false)
	}

	conv, messages, err := h.convMgr.LoadConversation(payload.ID)
	if err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInternal, err.Error(), false)
	}

	resp, _ := msg.Response(ipc.TypeConvData, map[string]interface{}{
		"conversation": conv,
		"messages":     messages,
	})
	client.Send(resp)
	return nil
}

func (h *Handler) handleListConvs(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	convs, err := h.convMgr.ListConversations(50)
	if err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInternal, err.Error(), false)
	}

	resp, _ := msg.Response(ipc.TypeConvList, convs)
	client.Send(resp)
	return nil
}

func (h *Handler) handleDeleteConv(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	var payload ipc.ConversationPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInvalidReq, "Invalid payload", false)
	}

	if err := h.convMgr.DeleteConversation(payload.ID); err != nil {
		return h.sendError(client, msg.RequestID, ipc.ErrCodeInternal, err.Error(), false)
	}

	resp, _ := msg.Response(ipc.TypeAck, nil)
	client.Send(resp)
	return nil
}

func (h *Handler) handleStatus(ctx context.Context, client *ipc.Client, msg *ipc.Message) error {
	convCount, _ := h.convMgr.CountConversations()

	providerName := "none"
	model := ""
	if h.provider != nil {
		providerName = h.provider.Name()
		if op, ok := h.provider.(*providers.OpenAIProvider); ok {
			model = op.GetModel()
		}
	}

	resp, _ := msg.Response(ipc.TypeStatus, ipc.StatusPayload{
		Running:       true,
		Provider:      providerName,
		Model:         model,
		Conversations: convCount,
	})
	client.Send(resp)
	return nil
}

func (h *Handler) sendError(client *ipc.Client, requestID, code, message string, retryable bool) error {
	msg, _ := ipc.NewMessage(ipc.TypeError, ipc.ErrorPayload{
		Code:      code,
		Message:   message,
		Retryable: retryable,
	})
	msg.RequestID = requestID
	client.Send(msg)
	return nil
}

func checkStatus() {
	cfg := daemon.DefaultConfig()

	conn, err := net.DialTimeout("unix", cfg.SocketPath, 2*time.Second)
	if err != nil {
		fmt.Println("❌ Daemon is not running")
		os.Exit(1)
	}
	defer conn.Close()

	// Send status request
	msg, _ := ipc.NewMessage(ipc.TypeStatus, nil)
	data, _ := json.Marshal(msg)
	data = append(data, '\n')
	conn.Write(data)

	// Set read timeout
	conn.SetReadDeadline(time.Now().Add(5 * time.Second))

	// Read response
	buf := make([]byte, 4096)
	n, err := conn.Read(buf)
	if err != nil {
		fmt.Println("❌ Failed to read response")
		os.Exit(1)
	}

	var resp ipc.Message
	if err := json.Unmarshal(buf[:n], &resp); err != nil {
		fmt.Println("❌ Invalid response")
		os.Exit(1)
	}

	var status ipc.StatusPayload
	json.Unmarshal(resp.Payload, &status)

	fmt.Println("✅ Daemon is running")
	fmt.Printf("   Provider: %s\n", status.Provider)
	fmt.Printf("   Model: %s\n", status.Model)
	fmt.Printf("   Conversations: %d\n", status.Conversations)
}

func runTest() {
	fmt.Println("Testing x-ai daemon...")

	// Check for --skip-chat flag
	skipChat := false
	for _, arg := range os.Args[2:] {
		if arg == "--skip-chat" || arg == "-s" {
			skipChat = true
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	var provider providers.Provider
	var providerName string

	// Try Gemini first (free tier!)
	geminiKey := os.Getenv("GOOGLE_API_KEY")
	if geminiKey != "" {
		fmt.Println("✅ GOOGLE_API_KEY found")
		p, err := providers.NewGeminiProvider(ctx, providers.GeminiConfig{
			APIKey:    geminiKey,
			Model:     "gemini-2.5-flash",
			MaxTokens: 4096,
			Timeout:   30 * time.Second,
		})
		if err != nil {
			fmt.Printf("⚠️  Gemini init failed: %v\n", err)
		} else {
			provider = p
			providerName = "Gemini"
		}
	}

	// Fallback to OpenAI
	if provider == nil {
		openaiKey := os.Getenv("OPENAI_API_KEY")
		if openaiKey != "" {
			fmt.Println("✅ OPENAI_API_KEY found")
			p, err := providers.NewOpenAIProvider(providers.OpenAIConfig{
				APIKey:  openaiKey,
				Model:   "gpt-4o-mini",
				Timeout: 30 * time.Second,
			})
			if err != nil {
				fmt.Printf("⚠️  OpenAI init failed: %v\n", err)
			} else {
				provider = p
				providerName = "OpenAI"
			}
		}
	}

	if provider == nil {
		fmt.Println("❌ No API key found. Set GOOGLE_API_KEY or OPENAI_API_KEY")
		os.Exit(1)
	}

	// Validate connection
	if err := provider.ValidateConnection(ctx); err != nil {
		fmt.Printf("❌ %s connection test failed: %v\n", providerName, err)
		os.Exit(1)
	}
	fmt.Printf("✅ %s connection successful\n", providerName)

	if skipChat {
		fmt.Println("⏭️  Skipping chat test (--skip-chat)")
		fmt.Println("✅ All tests passed!")
		return
	}

	// Quick chat test
	fmt.Println("Testing chat...")
	resp, err := provider.Chat(ctx, &providers.ChatRequest{
		Messages:  []providers.Message{{Role: "user", Content: "Say hello in 3 words"}},
		MaxTokens: 20,
	}, func(chunk *providers.StreamChunk) error {
		fmt.Print(chunk.Content)
		return nil
	})
	fmt.Println()

	if err != nil {
		fmt.Printf("❌ Chat test failed: %v\n", err)
		fmt.Println("   (Try: ./x-ai test --skip-chat)")
		os.Exit(1)
	}

	fmt.Printf("✅ Chat test successful (provider: %s, model: %s)\n", providerName, resp.Model)
}
