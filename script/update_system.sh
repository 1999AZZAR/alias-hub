#!/bin/bash

# ==============================================================================
# Smart System Update Script
#
# Original Author: Azzar Budiyanto (via FREA)
# Refined by: Gemini
# Version: 3.0
#
# This script provides a comprehensive update for Debian-based systems.
# It automatically elevates privileges, handles APT, Snap, Flatpak, and
# firmware updates, and notifies the user if a reboot is required.
#
# Enhancements in v3.0:
# - Added `set -e` and `set -o pipefail` for robustness.
# - Added firmware update step using `fwupdmgr`.
# - Added a check to notify the user if a reboot is required.
# - Standardized color scheme and output style.
# ==============================================================================

# --- Settings & Colors ---
set -e
set -o pipefail

C_RESET='[0m'
C_GREEN='[0;32m'
C_YELLOW='[0;33m'
C_BLUE='[0;34m'
C_BOLD='[1m'

# --- Auto-elevate to root if not already ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${C_YELLOW}This script requires root privileges. Attempting to re-run with sudo...${C_RESET}"
    exec sudo "$0" "$@"
    exit $?
fi

# --- Header ---
echo -e "${C_BOLD}==================================================${C_RESET}"
echo -e "${C_BOLD}  Smart System Update (v3.0)                  ${C_RESET}"
echo -e "${C_BOLD}  (Running with root privileges)              ${C_RESET}"
echo -e "${C_BOLD}==================================================${C_RESET}"
sleep 1

echo "Starting the comprehensive system update process..."
echo -e "${C_BOLD}--------------------------------------------------${C_RESET}"
sleep 1

# --- 1. APT Package Management ---
echo -e "
${C_BOLD}${C_BLUE}[1/4] Handling APT packages...${C_RESET}"

echo "-> Running 'apt update'..."
apt-get update -y

echo "-> Running 'apt upgrade'..."
apt-get upgrade -y
echo "-> Standard APT upgrade complete."
echo ""

# Attempt to install packages held back by phasing
echo "-> Checking for phased or held-back packages..."
# Use xargs to handle the list of packages cleanly
UPGRADABLE_PACKAGES=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}' | xargs)

if [ -n "$UPGRADABLE_PACKAGES" ]; then
    echo -e "   ${C_YELLOW}Found upgradable packages held back: $UPGRADABLE_PACKAGES${C_RESET}"
    echo "   -> Attempting to install them directly..."
    apt-get install -y $UPGRADABLE_PACKAGES
    echo -e "   ${C_GREEN}-> Direct installation/upgrade complete.${C_RESET}"
else
    echo "   -> No phased or held-back packages detected."
fi
echo ""

# Clean up unused packages and their configuration files
echo "-> Cleaning up orphaned packages ('apt autoremove')..."
apt-get --purge autoremove -y
echo -e "${C_GREEN}APT cleanup complete.${C_RESET}"
echo -e "${C_BOLD}--------------------------------------------------${C_RESET}"

# --- 2. Snap Package Management (Conditional) ---
echo -e "
${C_BOLD}${C_BLUE}[2/4] Handling Snap packages...${C_RESET}"
if command -v snap &>/dev/null; then
    if [[ $(snap list | wc -l) -gt 1 ]]; then
        echo "-> Snap is installed and packages detected. Refreshing..."
        snap refresh
        echo -e "${C_GREEN}Snap refresh complete.${C_RESET}"
    else
        echo -e "${C_YELLOW}Info: Snap command is present, but no packages are installed. Skipping.${C_RESET}"
    fi
else
    echo -e "${C_YELLOW}Info: Snap not found on this system. Skipping.${C_RESET}"
fi
echo -e "${C_BOLD}--------------------------------------------------${C_RESET}"

# --- 3. Flatpak Package Management (Conditional) ---
echo -e "
${C_BOLD}${C_BLUE}[3/4] Handling Flatpak packages...${C_RESET}"
if command -v flatpak &>/dev/null; then
    if [[ $(flatpak list --app | wc -l) -gt 0 ]]; then
        echo "-> Flatpak is installed and applications detected. Updating..."
        # Attempt to update, but if it fails, run repair and try again.
        # This handles cases where the Flatpak installation is corrupted.
        if ! flatpak update -y; then
            echo -e "   ${C_YELLOW}Flatpak update failed. Attempting to repair and retry...${C_RESET}"
            flatpak repair
            echo "   -> Retrying Flatpak update..."
            flatpak update -y
        fi
        echo -e "${C_GREEN}Flatpak update complete.${C_RESET}"
    else
        echo -e "${C_YELLOW}Info: Flatpak command is present, but no applications are installed. Skipping.${C_RESET}"
    fi
else
    echo -e "${C_YELLOW}Info: Flatpak not found on this system. Skipping.${C_RESET}"
fi
echo -e "${C_BOLD}--------------------------------------------------${C_RESET}"

# --- 4. Firmware Updates (Conditional) ---
echo -e "
${C_BOLD}${C_BLUE}[4/4] Handling Firmware updates...${C_RESET}"
if command -v fwupdmgr &>/dev/null; then
    echo "-> Checking for firmware updates with fwupdmgr..."
    fwupdmgr get-updates
    echo "-> Applying available firmware updates..."
    fwupdmgr update -y
    echo -e "${C_GREEN}Firmware update process complete.${C_RESET}"
else
    echo -e "${C_YELLOW}Info: fwupdmgr not found. Skipping firmware updates.${C_RESET}"
fi
echo -e "${C_BOLD}--------------------------------------------------${C_RESET}"


# --- Final Report & Reboot Check ---
echo -e "
${C_BOLD}${C_GREEN}✅ All update processes have completed!${C_RESET}"

if [ -f /var/run/reboot-required ]; then
    echo -e "
${C_BOLD}${C_YELLOW}**************************************************${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}*                                                *${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}*      REBOOT REQUIRED to apply all updates.     *${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}*                                                *${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}**************************************************${C_RESET}"
fi