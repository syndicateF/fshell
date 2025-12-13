#!/bin/bash
# =============================================================================
# Hardware Control Permissions Setup Script
# This script creates polkit rules to allow hardware control without password
# =============================================================================

set -e

RULES_FILE="/etc/polkit-1/rules.d/99-xshell-hardware.rules"
SUDOERS_FILE="/etc/sudoers.d/xshell-hardware"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     X-Shell Hardware Control Permissions Setup              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs root privileges.${NC}"
    echo -e "Please run: ${GREEN}sudo $0${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    echo -e "${RED}Error: Cannot determine actual user. Please run with sudo, not as root directly.${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting up permissions for user: ${GREEN}$ACTUAL_USER${NC}"
echo ""

# =============================================================================
# Option 1: Polkit Rules (Recommended for pkexec)
# =============================================================================
setup_polkit() {
    echo -e "${BLUE}[1/2] Creating Polkit rules...${NC}"
    
    cat > "$RULES_FILE" << 'POLKIT_EOF'
// X-Shell Hardware Control Rules
// Allows members of wheel group to control hardware without password

polkit.addRule(function(action, subject) {
    // Allow pkexec for specific hardware control commands
    if (action.id == "org.freedesktop.policykit.exec" &&
        subject.isInGroup("wheel")) {
        
        var dominated_commands = [
            "/usr/bin/nvidia-smi",
            "/usr/bin/sh"  // For echo commands to sysfs
        ];
        
        var dominated_prefixes = [
            "nvidia-smi",
            "echo"
        ];
        
        // Check if command line contains our allowed patterns
        var cmdline = action.lookup("command_line") || "";
        
        // Allow nvidia-smi commands
        if (cmdline.indexOf("nvidia-smi") !== -1) {
            return polkit.Result.YES;
        }
        
        // Allow echo to specific sysfs paths for hardware control
        if (cmdline.indexOf("echo") !== -1 && 
            (cmdline.indexOf("/sys/devices/system/cpu") !== -1 ||
             cmdline.indexOf("/sys/firmware/acpi/platform_profile") !== -1 ||
             cmdline.indexOf("/sys/class/backlight") !== -1 ||
             cmdline.indexOf("/sys/bus/platform/drivers/ideapad_acpi") !== -1)) {
            return polkit.Result.YES;
        }
        
        // Allow tee to Lenovo ideapad sysfs
        if (cmdline.indexOf("tee") !== -1 &&
            cmdline.indexOf("/sys/bus/platform/drivers/ideapad_acpi") !== -1) {
            return polkit.Result.YES;
        }

        // Allow powerprofilesctl (usually doesn't need pkexec but just in case)
        if (cmdline.indexOf("powerprofilesctl") !== -1) {
            return polkit.Result.YES;
        }
    }
    
    return polkit.Result.NOT_HANDLED;
});
POLKIT_EOF

    chmod 644 "$RULES_FILE"
    echo -e "${GREEN}✓ Polkit rules created at: $RULES_FILE${NC}"
}

# =============================================================================
# Option 2: Sudoers (Alternative/Backup)
# =============================================================================
setup_sudoers() {
    echo -e "${BLUE}[2/2] Creating sudoers rules...${NC}"
    
    cat > "$SUDOERS_FILE" << SUDOERS_EOF
# X-Shell Hardware Control - Allow without password
# This file allows specific hardware control commands without password

# NVIDIA GPU Control
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi -pl *
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi -pm *
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi --persistence-mode=*

# CPU Control (boost, governor, EPP)
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpufreq/boost
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

# Platform Profile (ACPI)
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/firmware/acpi/platform_profile

# Lenovo Ideapad Features (Battery Protection, USB Charging, Fn Lock)
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/usb_charging
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/fn_lock

# envycontrol (GPU Switching)
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/envycontrol -s *
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/envycontrol --switch *
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/envycontrol -q
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/envycontrol --query

# Generic shell for sysfs writes (more permissive, use with caution)
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/sh -c echo * > /sys/devices/system/cpu/*
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/sh -c echo * > /sys/firmware/acpi/platform_profile
$ACTUAL_USER ALL=(ALL) NOPASSWD: /usr/bin/sh -c echo * > /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode
SUDOERS_EOF

    chmod 440 "$SUDOERS_FILE"
    
    # Validate sudoers file
    if visudo -c -f "$SUDOERS_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Sudoers rules created at: $SUDOERS_FILE${NC}"
    else
        echo -e "${RED}✗ Sudoers file has errors, removing...${NC}"
        rm -f "$SUDOERS_FILE"
        return 1
    fi
}

# =============================================================================
# Main Setup
# =============================================================================

echo -e "${YELLOW}This will allow the following without password:${NC}"
echo "  • nvidia-smi power limit and persistence mode"
echo "  • CPU boost enable/disable"
echo "  • CPU governor changes"
echo "  • CPU energy performance preference"
echo "  • Platform profile changes"
echo "  • Lenovo battery conservation mode"
echo "  • Lenovo USB charging toggle"
echo "  • Lenovo Fn Lock toggle"
echo ""
read -p "Continue? [Y/n] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Aborted.${NC}"
    exit 0
fi

# Run setup
setup_polkit
setup_sudoers

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to log out and back in for changes to take effect.${NC}"
echo ""
echo -e "Files created:"
echo -e "  • ${BLUE}$RULES_FILE${NC}"
echo -e "  • ${BLUE}$SUDOERS_FILE${NC}"
echo ""
echo -e "To remove these permissions later, run:"
echo -e "  ${GREEN}sudo rm $RULES_FILE $SUDOERS_FILE${NC}"
