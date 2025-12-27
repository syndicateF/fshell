#!/bin/bash
# =============================================================================
# AI Chat Feature Uninstaller for x-shell
# Removes all AI chat related components while keeping helpers intact
# =============================================================================

set -e

echo "🔧 AI Chat Feature Uninstaller"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

XSHELL_DIR="${HOME}/.gemini/antigravity/scratch/x-shell"
DATA_DIR="${HOME}/.local/share/x-ai"

# 1. Stop x-ai daemon
echo -e "${YELLOW}[1/5]${NC} Stopping x-ai daemon..."
if pgrep -x x-ai > /dev/null; then
    killall x-ai 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Daemon stopped"
else
    echo -e "  ${GREEN}✓${NC} Daemon not running"
fi

# 2. Remove socket file
echo -e "${YELLOW}[2/5]${NC} Removing socket file..."
if [ -S /tmp/x-ai.sock ]; then
    rm -f /tmp/x-ai.sock
    echo -e "  ${GREEN}✓${NC} Socket removed"
else
    echo -e "  ${GREEN}✓${NC} Socket not found"
fi

# 3. Remove conversation data
echo -e "${YELLOW}[3/5]${NC} Removing conversation data..."
if [ -d "$DATA_DIR" ]; then
    rm -rf "$DATA_DIR"
    echo -e "  ${GREEN}✓${NC} Data directory removed: $DATA_DIR"
else
    echo -e "  ${GREEN}✓${NC} Data directory not found"
fi

# 4. Disable AI service (rename to .disabled)
echo -e "${YELLOW}[4/5]${NC} Disabling AI.qml service..."
AI_SERVICE="${XSHELL_DIR}/services/AI.qml"
if [ -f "$AI_SERVICE" ]; then
    mv "$AI_SERVICE" "${AI_SERVICE}.disabled"
    # Create stub to prevent import errors
    cat > "$AI_SERVICE" << 'EOF'
pragma Singleton
import Quickshell
import QtQuick

// AI Service - DISABLED
// To re-enable, rename AI.qml.disabled back to AI.qml
Singleton {
    id: root
    readonly property bool connected: false
    readonly property bool connecting: false
    readonly property bool loading: false
    readonly property bool streaming: false
    readonly property string currentProvider: ""
    readonly property string currentModel: ""
    readonly property string activeConversationId: ""
    readonly property string streamingContent: ""
    readonly property bool hasError: true
    readonly property string errorMessage: "AI service disabled"
    property ListModel conversations: ListModel {}
    property ListModel currentMessages: ListModel {}
    
    function sendMessage() {}
    function newConversation() {}
    function loadConversation() {}
    function refreshConversations() {}
}
EOF
    echo -e "  ${GREEN}✓${NC} AI service disabled (original saved as AI.qml.disabled)"
else
    echo -e "  ${RED}✗${NC} AI.qml not found"
fi

# 5. Summary
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ AI Chat Feature Uninstalled${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "What was removed:"
echo "  • x-ai daemon process"
echo "  • /tmp/x-ai.sock"
echo "  • ~/.local/share/x-ai/ (conversation data)"
echo "  • AI.qml disabled (stub created)"
echo ""
echo "What was kept:"
echo "  • helpers/x-ai/ (binary & source code)"
echo "  • AI.qml.disabled (original file backup)"
echo "  • Widget code in Drawers.qml (will just show 'disabled' state)"
echo ""
echo "To re-enable AI chat:"
echo "  1. mv services/AI.qml.disabled services/AI.qml"
echo "  2. Start daemon: GOOGLE_API_KEY=... ./helpers/x-ai/x-ai daemon"
echo "  3. Restart quickshell"
echo ""
echo "Please restart quickshell to apply changes:"
echo "  killall quickshell && quickshell -c ${XSHELL_DIR}"
