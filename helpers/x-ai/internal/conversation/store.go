// Package conversation manages conversation state and persistence.
package conversation

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	_ "github.com/mattn/go-sqlite3"
)

// Conversation represents a chat conversation
type Conversation struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Provider  string    `json:"provider"` // "openai" or "ollama"
	Model     string    `json:"model"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Archived  bool      `json:"archived"`
}

// Message represents a single message in a conversation
type Message struct {
	ID             string    `json:"id"`
	ConversationID string    `json:"conversation_id"`
	Role           string    `json:"role"` // "system", "user", "assistant"
	Content        string    `json:"content"`
	TokenCount     int       `json:"token_count,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
}

// Store handles conversation persistence in SQLite
type Store struct {
	db      *sql.DB
	dataDir string
}

// NewStore creates a new conversation store
func NewStore(dataDir string) (*Store, error) {
	// Ensure directory exists
	dbDir := filepath.Join(dataDir, "db")
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		return nil, fmt.Errorf("create db dir: %w", err)
	}

	dbPath := filepath.Join(dbDir, "conversations.db")
	db, err := sql.Open("sqlite3", dbPath+"?_journal_mode=WAL&_busy_timeout=5000")
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}

	store := &Store{
		db:      db,
		dataDir: dataDir,
	}

	if err := store.migrate(); err != nil {
		db.Close()
		return nil, fmt.Errorf("migrate: %w", err)
	}

	return store, nil
}

// migrate creates the database schema
func (s *Store) migrate() error {
	schema := `
	CREATE TABLE IF NOT EXISTS conversations (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		provider TEXT NOT NULL,
		model TEXT NOT NULL,
		created_at INTEGER NOT NULL,
		updated_at INTEGER NOT NULL,
		archived INTEGER DEFAULT 0
	);

	CREATE TABLE IF NOT EXISTS messages (
		id TEXT PRIMARY KEY,
		conversation_id TEXT NOT NULL,
		role TEXT NOT NULL,
		content TEXT NOT NULL,
		token_count INTEGER DEFAULT 0,
		created_at INTEGER NOT NULL,
		FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
	);

	CREATE INDEX IF NOT EXISTS idx_messages_conv ON messages(conversation_id);
	CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
	CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations(updated_at DESC);
	`

	_, err := s.db.Exec(schema)
	return err
}

// Close closes the database connection
func (s *Store) Close() error {
	return s.db.Close()
}

// CreateConversation creates a new conversation
func (s *Store) CreateConversation(provider, model, title string) (*Conversation, error) {
	now := time.Now()
	conv := &Conversation{
		ID:        uuid.New().String(),
		Title:     title,
		Provider:  provider,
		Model:     model,
		CreatedAt: now,
		UpdatedAt: now,
		Archived:  false,
	}

	_, err := s.db.Exec(`
		INSERT INTO conversations (id, title, provider, model, created_at, updated_at, archived)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, conv.ID, conv.Title, conv.Provider, conv.Model, now.Unix(), now.Unix(), 0)

	if err != nil {
		return nil, fmt.Errorf("insert conversation: %w", err)
	}

	return conv, nil
}

// GetConversation retrieves a conversation by ID
func (s *Store) GetConversation(id string) (*Conversation, error) {
	row := s.db.QueryRow(`
		SELECT id, title, provider, model, created_at, updated_at, archived
		FROM conversations WHERE id = ?
	`, id)

	conv := &Conversation{}
	var createdAt, updatedAt int64
	var archived int

	err := row.Scan(&conv.ID, &conv.Title, &conv.Provider, &conv.Model, &createdAt, &updatedAt, &archived)
	if err == sql.ErrNoRows {
		return nil, nil // Not found
	}
	if err != nil {
		return nil, fmt.Errorf("scan conversation: %w", err)
	}

	conv.CreatedAt = time.Unix(createdAt, 0)
	conv.UpdatedAt = time.Unix(updatedAt, 0)
	conv.Archived = archived != 0

	return conv, nil
}

// ListConversations returns all conversations, newest first
func (s *Store) ListConversations(limit int, includeArchived bool) ([]*Conversation, error) {
	query := `
		SELECT id, title, provider, model, created_at, updated_at, archived
		FROM conversations
		WHERE archived = 0 OR archived = ?
		ORDER BY updated_at DESC
		LIMIT ?
	`

	archivedFilter := 0
	if includeArchived {
		archivedFilter = 1
	}

	rows, err := s.db.Query(query, archivedFilter, limit)
	if err != nil {
		return nil, fmt.Errorf("query conversations: %w", err)
	}
	defer rows.Close()

	var convs []*Conversation
	for rows.Next() {
		conv := &Conversation{}
		var createdAt, updatedAt int64
		var archived int

		if err := rows.Scan(&conv.ID, &conv.Title, &conv.Provider, &conv.Model, &createdAt, &updatedAt, &archived); err != nil {
			return nil, fmt.Errorf("scan conversation: %w", err)
		}

		conv.CreatedAt = time.Unix(createdAt, 0)
		conv.UpdatedAt = time.Unix(updatedAt, 0)
		conv.Archived = archived != 0
		convs = append(convs, conv)
	}

	return convs, rows.Err()
}

// UpdateConversationTitle updates the title
func (s *Store) UpdateConversationTitle(id, title string) error {
	_, err := s.db.Exec(`
		UPDATE conversations SET title = ?, updated_at = ? WHERE id = ?
	`, title, time.Now().Unix(), id)
	return err
}

// UpdateConversationTime updates the updated_at timestamp
func (s *Store) UpdateConversationTime(id string) error {
	_, err := s.db.Exec(`
		UPDATE conversations SET updated_at = ? WHERE id = ?
	`, time.Now().Unix(), id)
	return err
}

// ArchiveConversation archives a conversation
func (s *Store) ArchiveConversation(id string) error {
	_, err := s.db.Exec(`
		UPDATE conversations SET archived = 1, updated_at = ? WHERE id = ?
	`, time.Now().Unix(), id)
	return err
}

// DeleteConversation deletes a conversation and its messages
func (s *Store) DeleteConversation(id string) error {
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Delete messages first (foreign key constraint)
	if _, err := tx.Exec("DELETE FROM messages WHERE conversation_id = ?", id); err != nil {
		return fmt.Errorf("delete messages: %w", err)
	}

	// Delete conversation
	if _, err := tx.Exec("DELETE FROM conversations WHERE id = ?", id); err != nil {
		return fmt.Errorf("delete conversation: %w", err)
	}

	return tx.Commit()
}

// AddMessage adds a message to a conversation
func (s *Store) AddMessage(conversationID, role, content string, tokenCount int) (*Message, error) {
	return s.AddMessageWithID(conversationID, uuid.New().String(), role, content, tokenCount)
}

// AddMessageWithID adds a message with a pre-generated ID (for streaming)
func (s *Store) AddMessageWithID(conversationID, id, role, content string, tokenCount int) (*Message, error) {
	now := time.Now()
	msg := &Message{
		ID:             id,
		ConversationID: conversationID,
		Role:           role,
		Content:        content,
		TokenCount:     tokenCount,
		CreatedAt:      now,
	}

	_, err := s.db.Exec(`
		INSERT INTO messages (id, conversation_id, role, content, token_count, created_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, msg.ID, msg.ConversationID, msg.Role, msg.Content, msg.TokenCount, now.Unix())

	if err != nil {
		return nil, fmt.Errorf("insert message: %w", err)
	}

	// Update conversation timestamp
	s.UpdateConversationTime(conversationID)

	return msg, nil
}

// GetMessages retrieves all messages for a conversation
func (s *Store) GetMessages(conversationID string) ([]*Message, error) {
	rows, err := s.db.Query(`
		SELECT id, conversation_id, role, content, token_count, created_at
		FROM messages
		WHERE conversation_id = ?
		ORDER BY created_at ASC
	`, conversationID)
	if err != nil {
		return nil, fmt.Errorf("query messages: %w", err)
	}
	defer rows.Close()

	var messages []*Message
	for rows.Next() {
		msg := &Message{}
		var createdAt int64

		if err := rows.Scan(&msg.ID, &msg.ConversationID, &msg.Role, &msg.Content, &msg.TokenCount, &createdAt); err != nil {
			return nil, fmt.Errorf("scan message: %w", err)
		}

		msg.CreatedAt = time.Unix(createdAt, 0)
		messages = append(messages, msg)
	}

	return messages, rows.Err()
}

// GetRecentMessages retrieves the last N messages
func (s *Store) GetRecentMessages(conversationID string, limit int) ([]*Message, error) {
	// Get in reverse order then reverse
	rows, err := s.db.Query(`
		SELECT id, conversation_id, role, content, token_count, created_at
		FROM messages
		WHERE conversation_id = ?
		ORDER BY created_at DESC
		LIMIT ?
	`, conversationID, limit)
	if err != nil {
		return nil, fmt.Errorf("query messages: %w", err)
	}
	defer rows.Close()

	var messages []*Message
	for rows.Next() {
		msg := &Message{}
		var createdAt int64

		if err := rows.Scan(&msg.ID, &msg.ConversationID, &msg.Role, &msg.Content, &msg.TokenCount, &createdAt); err != nil {
			return nil, fmt.Errorf("scan message: %w", err)
		}

		msg.CreatedAt = time.Unix(createdAt, 0)
		messages = append(messages, msg)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Reverse to get chronological order
	for i, j := 0, len(messages)-1; i < j; i, j = i+1, j-1 {
		messages[i], messages[j] = messages[j], messages[i]
	}

	return messages, nil
}

// CountMessages returns the number of messages in a conversation
func (s *Store) CountMessages(conversationID string) (int, error) {
	var count int
	err := s.db.QueryRow(`
		SELECT COUNT(*) FROM messages WHERE conversation_id = ?
	`, conversationID).Scan(&count)
	return count, err
}

// GetTotalTokens returns the total token count for a conversation
func (s *Store) GetTotalTokens(conversationID string) (int, error) {
	var total int
	err := s.db.QueryRow(`
		SELECT COALESCE(SUM(token_count), 0) FROM messages WHERE conversation_id = ?
	`, conversationID).Scan(&total)
	return total, err
}

// CountConversations returns the total number of conversations
func (s *Store) CountConversations() (int, error) {
	var count int
	err := s.db.QueryRow(`SELECT COUNT(*) FROM conversations WHERE archived = 0`).Scan(&count)
	return count, err
}
