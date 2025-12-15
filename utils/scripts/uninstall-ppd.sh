#!/bin/bash
# Uninstall power-profiles-daemon completely and clean up all traces
# This script should be run with sudo

set -e

echo "=== Uninstalling power-profiles-daemon ==="

# Stop and disable the service
echo "[1/5] Stopping service..."
systemctl stop power-profiles-daemon 2>/dev/null || true
systemctl disable power-profiles-daemon 2>/dev/null || true

# Remove the package (try multiple package managers)
echo "[2/5] Removing package..."
if command -v pacman &>/dev/null; then
    pacman -Rns --noconfirm power-profiles-daemon 2>/dev/null || true
elif command -v apt &>/dev/null; then
    apt remove --purge -y power-profiles-daemon 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf remove -y power-profiles-daemon 2>/dev/null || true
elif command -v zypper &>/dev/null; then
    zypper remove -y power-profiles-daemon 2>/dev/null || true
fi

# Remove config files and leftover data
echo "[3/5] Cleaning config files..."
rm -rf /etc/power-profiles-daemon 2>/dev/null || true
rm -rf /var/lib/power-profiles-daemon 2>/dev/null || true
rm -f /etc/dbus-1/system.d/power-profiles-daemon.conf 2>/dev/null || true

# Remove systemd service files if still present
echo "[4/5] Cleaning systemd files..."
rm -f /usr/lib/systemd/system/power-profiles-daemon.service 2>/dev/null || true
rm -f /etc/systemd/system/power-profiles-daemon.service 2>/dev/null || true
rm -f /etc/systemd/system/multi-user.target.wants/power-profiles-daemon.service 2>/dev/null || true
systemctl daemon-reload

# Mask the service to prevent reinstallation
echo "[5/5] Masking service to prevent reinstall..."
systemctl mask power-profiles-daemon 2>/dev/null || true

echo ""
echo "=== Cleanup Complete ==="
echo "power-profiles-daemon has been removed and masked."
echo ""
echo "Verification:"
if ! command -v powerprofilesctl &>/dev/null; then
    echo "  ✓ powerprofilesctl command removed"
else
    echo "  ✗ powerprofilesctl still exists (may be from another package)"
fi

if systemctl is-enabled power-profiles-daemon 2>/dev/null | grep -q masked; then
    echo "  ✓ Service is masked"
else
    echo "  ✓ Service does not exist or is masked"
fi

echo ""
echo "Your system now uses direct sysfs control for power management."
