#!/bin/bash

# ==============================================================================
# Smart System Update Script
#
# Original Author: Azzar Budiyanto (via FREA)
# Refined by: Gemini
# Version: 2.1
#
# This script provides a comprehensive update for Debian-based systems.
# It automatically elevates its own privileges using 'sudo' if not run as root.
# It handles APT, Snap, and Flatpak package managers, automatically
# detecting their presence and only running updates if they are in use.
# It also includes a cleanup step for orphaned packages.
#
# Usage:
# 1. Grant execute permissions: chmod +x update_system.sh
# 2. Execute the script:        ./update_system.sh
#    (It will automatically prompt for a sudo password if needed)
# ==============================================================================

# --- Auto-elevate to root if not already ---
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Attempting to re-run with sudo..."
    # Re-execute the script with sudo, passing along all original arguments.
    sudo "$0" "$@"
    # Exit the original, non-privileged script with the exit code of the sudo command.
    exit $?
fi

# --- Configuration & Styling ---
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_NC='\033[0m' # No Color

# --- Header ---
echo -e "${COLOR_BLUE}=================================================="
echo -e "  Smart System Update (v2.1)                  "
echo -e "  (Running with root privileges)              "
echo -e "==================================================${COLOR_NC}"
sleep 1

echo "Starting the comprehensive system update process..."
echo "--------------------------------------------------"
sleep 1

# --- 1. APT Package Management ---
echo -e "${COLOR_GREEN}[1/3] Handling APT packages...${COLOR_NC}"

# Update package lists and upgrade installed packages
echo "-> Running 'apt update' and 'apt upgrade'..."
apt update && apt upgrade -y
echo "-> Standard APT upgrade complete."
echo ""

# Attempt to install packages held back by phasing
echo "-> Checking for phased or held-back packages..."
UPGRADABLE_PACKAGES=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}' | tr '\n' ' ')

if [ -n "$UPGRADABLE_PACKAGES" ]; then
    echo -e "   ${COLOR_YELLOW}Found upgradable packages held back: $UPGRADABLE_PACKAGES${COLOR_NC}"
    echo "   -> Attempting to install them directly..."
    apt install -y $UPGRADABLE_PACKAGES
    echo "   -> Direct installation/upgrade complete."
else
    echo "   -> No phased or held-back packages detected."
fi
echo ""

# Clean up unused packages and their configuration files
echo "-> Cleaning up orphaned packages ('apt autoremove')..."
apt --purge autoremove -y
echo "-> APT cleanup complete."
echo "--------------------------------------------------"

# --- 2. Snap Package Management (Conditional) ---
echo -e "${COLOR_GREEN}[2/3] Handling Snap packages...${COLOR_NC}"
if command -v snap &>/dev/null; then
    # Check if there are any snaps installed before trying to refresh
    if [[ $(snap list | wc -l) -gt 1 ]]; then
        echo "-> Snap is installed and packages detected. Refreshing..."
        snap refresh
        echo "-> Snap refresh complete."
    else
        echo -e "-> ${COLOR_YELLOW}Info: Snap command is present, but no packages are installed. Skipping.${COLOR_NC}"
    fi
else
    echo -e "-> ${COLOR_YELLOW}Info: Snap not found on this system. Skipping.${COLOR_NC}"
fi
echo "--------------------------------------------------"

# --- 3. Flatpak Package Management (Conditional) ---
echo -e "${COLOR_GREEN}[3/3] Handling Flatpak packages...${COLOR_NC}"
if command -v flatpak &>/dev/null; then
    # Check if there are any flatpaks installed before trying to update
    if [[ $(flatpak list --app | wc -l) -gt 0 ]]; then
        echo "-> Flatpak is installed and applications detected. Updating..."
        flatpak update -y
        echo "-> Flatpak update complete."
    else
        echo -e "-> ${COLOR_YELLOW}Info: Flatpak command is present, but no applications are installed. Skipping.${COLOR_NC}"
    fi
else
    echo -e "-> ${COLOR_YELLOW}Info: Flatpak not found on this system. Skipping.${COLOR_NC}"
fi
echo "--------------------------------------------------"

# --- Final Report ---
echo -e "${COLOR_BLUE}=================================================="
echo -e "  System update process has completed successfully! "
echo -e "==================================================${COLOR_NC}"
