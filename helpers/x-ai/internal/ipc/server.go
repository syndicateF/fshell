// Package ipc implements Unix socket IPC for QML communication.
// All messages are JSON-encoded for easy parsing on both ends.
package ipc

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Message types for IPC protocol
const (
	// Requests (UI → Daemon)
	TypeChat        = "chat"         // Send message
	TypeNewConv     = "new_conv"     // Create conversation
	TypeLoadConv    = "load_conv"    // Load conversation
	TypeDeleteConv  = "delete_conv"  // Delete conversation
	TypeListConvs   = "list_convs"   // Get all conversations
	TypeSetProvider = "set_provider" // Switch provider
	TypeSetModel    = "set_model"    // Change model
	TypeCancel      = "cancel"       // Cancel current request
	TypeRetry       = "retry"        // Retry failed request

	// Responses (Daemon → UI)
	TypeChatChunk    = "chat_chunk"    // Streaming chunk
	TypeChatComplete = "chat_complete" // Stream done
	TypeError        = "error"         // Error occurred
	TypeStatus       = "status"        // Status update
	TypeHeartbeat    = "heartbeat"     // Keep-alive
	TypeConvList     = "conv_list"     // Conversations list
	TypeConvData     = "conv_data"     // Conversation loaded
	TypeAck          = "ack"           // Request acknowledged
)

// Message is the base IPC message format
type Message struct {
	Type      string          `json:"type"`
	RequestID string          `json:"request_id"`
	Payload   json.RawMessage `json:"payload,omitempty"`
	Timestamp int64           `json:"timestamp"`
}

// NewMessage creates a new message with auto-generated ID and timestamp
func NewMessage(msgType string, payload interface{}) (*Message, error) {
	var payloadBytes json.RawMessage
	if payload != nil {
		var err error
		payloadBytes, err = json.Marshal(payload)
		if err != nil {
			return nil, fmt.Errorf("marshal payload: %w", err)
		}
	}

	return &Message{
		Type:      msgType,
		RequestID: uuid.New().String(),
		Payload:   payloadBytes,
		Timestamp: time.Now().UnixMilli(),
	}, nil
}

// Response creates a response message for a request
func (m *Message) Response(msgType string, payload interface{}) (*Message, error) {
	resp, err := NewMessage(msgType, payload)
	if err != nil {
		return nil, err
	}
	resp.RequestID = m.RequestID // Keep same request ID
	return resp, nil
}

// ErrorPayload for error responses
type ErrorPayload struct {
	Code       string `json:"code"`
	Message    string `json:"message"`
	Retryable  bool   `json:"retryable"`
	RetryAfter int    `json:"retry_after,omitempty"` // seconds
	Details    string `json:"details,omitempty"`
}

// Error codes
const (
	ErrCodeRateLimit    = "RATE_LIMIT"
	ErrCodeAuthFailed   = "AUTH_FAILED"
	ErrCodeNetworkErr   = "NETWORK_ERROR"
	ErrCodeServerDown   = "SERVER_DOWN"
	ErrCodeTokenLimit   = "TOKEN_LIMIT"
	ErrCodeInvalidReq   = "INVALID_REQUEST"
	ErrCodeCancelled    = "CANCELLED"
	ErrCodeLocalNoModel = "LOCAL_NO_MODEL"
	ErrCodeInternal     = "INTERNAL_ERROR"
)

// ChatPayload for chat requests
type ChatPayload struct {
	ConversationID string   `json:"conversation_id,omitempty"`
	Content        string   `json:"content"`
	Attachments    []string `json:"attachments,omitempty"` // File paths
}

// ChatChunkPayload for streaming response chunks
type ChatChunkPayload struct {
	ConversationID string `json:"conversation_id"`
	MessageID      string `json:"message_id"`
	Content        string `json:"content"` // Delta content
	Done           bool   `json:"done"`
}

// ConversationPayload for conversation operations
type ConversationPayload struct {
	ID    string `json:"id"`
	Title string `json:"title,omitempty"`
}

// StatusPayload for daemon status
type StatusPayload struct {
	Running       bool   `json:"running"`
	Provider      string `json:"provider"`
	Model         string `json:"model"`
	Conversations int    `json:"conversations"`
	IdleSeconds   int    `json:"idle_seconds"`
}

// HeartbeatPayload for keep-alive
type HeartbeatPayload struct {
	Timestamp int64 `json:"timestamp"`
}

// Client represents a connected IPC client
type Client struct {
	id     string
	conn   net.Conn
	server *Server
	sendCh chan *Message
	ctx    context.Context
	cancel context.CancelFunc
}

// Server handles IPC connections
type Server struct {
	socketPath string
	listener   net.Listener
	clients    map[string]*Client
	clientsMu  sync.RWMutex
	handler    MessageHandler
	ctx        context.Context
	cancel     context.CancelFunc
	wg         sync.WaitGroup
}

// MessageHandler processes incoming messages
type MessageHandler interface {
	HandleMessage(ctx context.Context, client *Client, msg *Message) error
}

// NewServer creates a new IPC server
func NewServer(socketPath string, handler MessageHandler) (*Server, error) {
	// Remove existing socket file
	if err := os.Remove(socketPath); err != nil && !os.IsNotExist(err) {
		return nil, fmt.Errorf("remove old socket: %w", err)
	}

	listener, err := net.Listen("unix", socketPath)
	if err != nil {
		return nil, fmt.Errorf("listen: %w", err)
	}

	// Set socket permissions (owner only)
	if err := os.Chmod(socketPath, 0600); err != nil {
		listener.Close()
		return nil, fmt.Errorf("chmod socket: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &Server{
		socketPath: socketPath,
		listener:   listener,
		clients:    make(map[string]*Client),
		handler:    handler,
		ctx:        ctx,
		cancel:     cancel,
	}, nil
}

// Start begins accepting connections
func (s *Server) Start() {
	s.wg.Add(1)
	go s.acceptLoop()
	log.Printf("IPC server listening on %s", s.socketPath)
}

// Stop gracefully shuts down the server
func (s *Server) Stop() error {
	log.Printf("IPC server shutting down...")
	s.cancel()
	s.listener.Close()

	// Close all client connections
	s.clientsMu.Lock()
	for _, client := range s.clients {
		client.cancel()
		client.conn.Close()
	}
	s.clientsMu.Unlock()

	s.wg.Wait()

	// Remove socket file
	os.Remove(s.socketPath)

	log.Printf("IPC server stopped")
	return nil
}

// acceptLoop handles incoming connections
func (s *Server) acceptLoop() {
	defer s.wg.Done()

	for {
		conn, err := s.listener.Accept()
		if err != nil {
			select {
			case <-s.ctx.Done():
				return // Server shutting down
			default:
				log.Printf("IPC accept error: %v", err)
				continue
			}
		}

		client := s.newClient(conn)
		s.wg.Add(2)
		go s.handleClient(client)
		go s.writeLoop(client)
	}
}

// newClient creates a new client instance
func (s *Server) newClient(conn net.Conn) *Client {
	ctx, cancel := context.WithCancel(s.ctx)
	client := &Client{
		id:     uuid.New().String(),
		conn:   conn,
		server: s,
		sendCh: make(chan *Message, 100),
		ctx:    ctx,
		cancel: cancel,
	}

	s.clientsMu.Lock()
	s.clients[client.id] = client
	s.clientsMu.Unlock()

	log.Printf("IPC client connected: %s", client.id)
	return client
}

// handleClient reads messages from a client
func (s *Server) handleClient(client *Client) {
	defer s.wg.Done()
	defer s.removeClient(client)
	defer client.conn.Close()

	scanner := bufio.NewScanner(client.conn)
	// Increase buffer size for large messages
	scanner.Buffer(make([]byte, 64*1024), 1024*1024)

	for scanner.Scan() {
		select {
		case <-client.ctx.Done():
			return
		default:
		}

		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}

		var msg Message
		if err := json.Unmarshal(line, &msg); err != nil {
			log.Printf("IPC parse error from %s: %v", client.id, err)
			s.sendError(client, "", ErrCodeInvalidReq, "Invalid JSON", false)
			continue
		}

		// Handle message in goroutine to not block reading
		go func(m Message) {
			if err := s.handler.HandleMessage(client.ctx, client, &m); err != nil {
				log.Printf("IPC handler error: %v", err)
			}
		}(msg)
	}

	if err := scanner.Err(); err != nil {
		log.Printf("IPC read error from %s: %v", client.id, err)
	}
}

// writeLoop handles sending messages to a client
func (s *Server) writeLoop(client *Client) {
	defer s.wg.Done()

	for {
		select {
		case <-client.ctx.Done():
			return
		case msg := <-client.sendCh:
			data, err := json.Marshal(msg)
			if err != nil {
				log.Printf("IPC marshal error: %v", err)
				continue
			}

			// Write message + newline
			data = append(data, '\n')
			if _, err := client.conn.Write(data); err != nil {
				log.Printf("IPC write error to %s: %v", client.id, err)
				client.cancel()
				return
			}
		}
	}
}

// removeClient removes a client from the server
func (s *Server) removeClient(client *Client) {
	s.clientsMu.Lock()
	delete(s.clients, client.id)
	s.clientsMu.Unlock()
	close(client.sendCh)
	log.Printf("IPC client disconnected: %s", client.id)
}

// Send queues a message to be sent to the client (safe for closed channel)
func (c *Client) Send(msg *Message) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("IPC send recovered from panic for %s: %v", c.id, r)
		}
	}()

	select {
	case c.sendCh <- msg:
	default:
		log.Printf("IPC send buffer full or closed for %s, dropping message", c.id)
	}
}

// SendPayload is a convenience method to send a typed payload
func (c *Client) SendPayload(msgType string, payload interface{}) error {
	msg, err := NewMessage(msgType, payload)
	if err != nil {
		return err
	}
	c.Send(msg)
	return nil
}

// Broadcast sends a message to all connected clients
func (s *Server) Broadcast(msg *Message) {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()

	for _, client := range s.clients {
		client.Send(msg)
	}
}

// sendError sends an error response to a client
func (s *Server) sendError(client *Client, requestID string, code string, message string, retryable bool) {
	msg, _ := NewMessage(TypeError, ErrorPayload{
		Code:      code,
		Message:   message,
		Retryable: retryable,
	})
	if requestID != "" {
		msg.RequestID = requestID
	}
	client.Send(msg)
}

// ClientCount returns the number of connected clients
func (s *Server) ClientCount() int {
	s.clientsMu.RLock()
	defer s.clientsMu.RUnlock()
	return len(s.clients)
}
