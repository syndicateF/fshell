// Package fetcher provides Planify database access.
package fetcher

import (
	"database/sql"
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"

	"x-fetch/internal/models"
)

// FetchPlanifyTasks reads today's incomplete tasks from Planify database.
func FetchPlanifyTasks() ([]models.PlanifyTask, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	dbPath := filepath.Join(home, ".local", "share", "io.github.alainm23.planify", "database.db")

	// Check if database exists
	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		// Planify not installed, return empty (not an error)
		return []models.PlanifyTask{}, nil
	}

	db, err := sql.Open("sqlite3", dbPath+"?mode=ro")
	if err != nil {
		return nil, err
	}
	defer db.Close()

	// Query uncompleted tasks
	rows, err := db.Query(`
		SELECT id, content, due, priority 
		FROM Items 
		WHERE checked = 0 AND is_deleted = 0 
		ORDER BY priority DESC, day_order ASC 
		LIMIT 10
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	today := time.Now().Format("2006-01-02")
	var tasks []models.PlanifyTask

	for rows.Next() {
		var id, content string
		var dueJSON sql.NullString
		var priority int

		if err := rows.Scan(&id, &content, &dueJSON, &priority); err != nil {
			continue
		}

		// Parse due date from JSON
		dueDate := ""
		if dueJSON.Valid && dueJSON.String != "" {
			var dueObj struct {
				Date string `json:"date"`
			}
			if json.Unmarshal([]byte(dueJSON.String), &dueObj) == nil {
				dueDate = dueObj.Date
			}
		}

		task := models.PlanifyTask{
			ID:       id,
			Content:  content,
			DueDate:  dueDate,
			Priority: priority,
			IsToday:  dueDate == today,
			HasDate:  dueDate != "",
		}

		// Filter: include if no date OR due today
		if !task.HasDate || task.IsToday {
			tasks = append(tasks, task)
		}
	}

	// Limit to 5 tasks for UI display
	if len(tasks) > 5 {
		tasks = tasks[:5]
	}

	return tasks, nil
}
