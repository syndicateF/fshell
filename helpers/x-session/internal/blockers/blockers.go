// Package blockers is intentionally empty.
//
// x-session does NOT inspect compositor/window state.
// There is no freedesktop.org standard for listing windows.
// Each compositor (Hyprland, Sway, GNOME, KDE) has its own incompatible API.
//
// x-session relies ONLY on:
// - systemd inhibitors (org.freedesktop.login1.Manager.ListInhibitors)
// - User-configured hooks (hooks.yaml)
//
// If an application needs to block shutdown, it should register
// a systemd inhibitor. That is the standard.
//
// See: https://www.freedesktop.org/wiki/Software/systemd/inhibit/
package blockers
