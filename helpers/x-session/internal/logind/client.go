// Package logind provides a client for systemd-logind D-Bus interface
// Handles power actions and inhibitor management via org.freedesktop.login1
package logind

import (
	"fmt"
	"os"

	"github.com/godbus/dbus/v5"
)

const (
	logindDest      = "org.freedesktop.login1"
	logindPath      = "/org/freedesktop/login1"
	logindInterface = "org.freedesktop.login1.Manager"
)

// Client wraps the logind D-Bus connection
type Client struct {
	conn *dbus.Conn
	obj  dbus.BusObject
}

// InhibitorLock represents an active inhibitor lock (file descriptor based)
type InhibitorLock struct {
	fd   *os.File
	what string
	why  string
}

// New creates a new logind client connected to system bus
func New() (*Client, error) {
	conn, err := dbus.SystemBus()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to system bus: %w", err)
	}

	return &Client{
		conn: conn,
		obj:  conn.Object(logindDest, logindPath),
	}, nil
}

// Close closes the D-Bus connection
func (c *Client) Close() error {
	return c.conn.Close()
}

// TakeInhibitor acquires a delay inhibitor lock
// Returns an InhibitorLock that MUST be closed to release the lock
// If the process crashes, kernel auto-releases the FD (built-in failsafe)
func (c *Client) TakeInhibitor(what, who, why, mode string) (*InhibitorLock, error) {
	var fd dbus.UnixFD
	err := c.obj.Call(logindInterface+".Inhibit", 0, what, who, why, mode).Store(&fd)
	if err != nil {
		return nil, fmt.Errorf("failed to take inhibitor: %w", err)
	}

	// Convert UnixFD to os.File for proper cleanup
	file := os.NewFile(uintptr(fd), fmt.Sprintf("inhibitor-%s", what))
	if file == nil {
		return nil, fmt.Errorf("failed to create file from FD")
	}

	return &InhibitorLock{
		fd:   file,
		what: what,
		why:  why,
	}, nil
}

// Release releases the inhibitor lock
func (l *InhibitorLock) Release() error {
	if l.fd != nil {
		err := l.fd.Close()
		l.fd = nil
		return err
	}
	return nil
}

// PowerOff initiates system shutdown
func (c *Client) PowerOff(interactive bool) error {
	return c.obj.Call(logindInterface+".PowerOff", 0, interactive).Err
}

// Reboot initiates system reboot
func (c *Client) Reboot(interactive bool) error {
	return c.obj.Call(logindInterface+".Reboot", 0, interactive).Err
}

// Suspend initiates system suspend
func (c *Client) Suspend(interactive bool) error {
	return c.obj.Call(logindInterface+".Suspend", 0, interactive).Err
}

// Hibernate initiates system hibernate
func (c *Client) Hibernate(interactive bool) error {
	return c.obj.Call(logindInterface+".Hibernate", 0, interactive).Err
}

// Inhibitor represents an active inhibitor from ListInhibitors
type Inhibitor struct {
	What string
	Who  string
	Why  string
	Mode string
	UID  uint32
	PID  uint32
}

// ListInhibitors returns all active inhibitors
func (c *Client) ListInhibitors() ([]Inhibitor, error) {
	var result [][]interface{}
	err := c.obj.Call(logindInterface+".ListInhibitors", 0).Store(&result)
	if err != nil {
		return nil, fmt.Errorf("failed to list inhibitors: %w", err)
	}

	inhibitors := make([]Inhibitor, 0, len(result))
	for _, item := range result {
		if len(item) >= 6 {
			inhibitors = append(inhibitors, Inhibitor{
				What: item[0].(string),
				Who:  item[1].(string),
				Why:  item[2].(string),
				Mode: item[3].(string),
				UID:  item[4].(uint32),
				PID:  item[5].(uint32),
			})
		}
	}
	return inhibitors, nil
}
