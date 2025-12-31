#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="x-session"
INSTALL_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"
CONFIG_DIR="$HOME/.config/x-session"

echo "Building x-session..."
cd "$SCRIPT_DIR"
go build -o "$BINARY_NAME" ./cmd/main.go

echo "Installing binary to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

echo "Installing systemd service..."
mkdir -p "$SERVICE_DIR"
cp "$SCRIPT_DIR/systemd/x-session.service" "$SERVICE_DIR/"

echo "Creating default config..."
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/hooks.yaml" ]; then
    cat > "$CONFIG_DIR/hooks.yaml" << 'EOF'
# x-session pre-shutdown hooks
# Each hook runs before shutdown/reboot with its own timeout
hooks:
  - name: docker
    enabled: true
    timeout: 15s
    command: ["sh", "-c", "docker ps -q | xargs -r docker stop --time=5"]
    
  - name: sync
    enabled: true
    timeout: 5s
    command: ["sync"]
    
  # Uncomment to enable libvirt VM shutdown
  # - name: libvirt
  #   enabled: true
  #   timeout: 30s
  #   command: ["sh", "-c", "virsh list --name --state-running | xargs -r -I{} virsh shutdown {}"]
EOF
    echo "Created default hooks config at $CONFIG_DIR/hooks.yaml"
else
    echo "Hooks config already exists, skipping..."
fi

echo "Reloading systemd..."
systemctl --user daemon-reload

echo "Enabling x-session service..."
systemctl --user enable x-session.service

echo ""
echo "Installation complete!"
echo ""
echo "To start the service now:"
echo "  systemctl --user start x-session"
echo ""
echo "To check status:"
echo "  systemctl --user status x-session"
echo ""
echo "To view logs:"
echo "  journalctl --user -u x-session -f"
