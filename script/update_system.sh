#!/bin/bash

# ==============================================================================
# Smart System Update Script
# Original Author: Azzar Budiyanto (via FREA)
# Refined by: Gemini
# Version: 3.2
#
# Comprehensive system update for Debian-based systems.
# Handles APT, Snap, Flatpak, and Firmware.
#
# Refinements in v3.2:
# - Added Dry Run mode (-d / --dry-run).
# - Better error handling for fwupdmgr.
# - Improved formatting and checks.
# - Added help flag.
# ==============================================================================

# --- Settings ---
set -e
set -o pipefail

# --- Colors ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'

# --- Variables ---
DRY_RUN=false
FULL_UPGRADE=false

# --- Usage ---
usage() {
    echo -e "${C_BOLD}Usage:${C_RESET} $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -d, --dry-run     Simulate update process."
    echo "  -f, --full        Perform a full upgrade (dist-upgrade) instead of safe upgrade."
    echo "  -h, --help        Show this help message."
    echo
    exit 0
}

# --- Parse Arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true ;;
        -f|--full) FULL_UPGRADE=true ;;
        -h|--help) usage ;;
        *) echo -e "${C_RED}Unknown parameter: $1${C_RESET}"; usage ;;
    esac
    shift
done

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${C_YELLOW}Dry run active (non-root).${C_RESET}"
    else
        echo -e "${C_YELLOW}Root required. Elevating...${C_RESET}"
        exec sudo "$0" "$@" "${ARGS[@]}"
        exit $?
    fi
fi

# --- Helper ---
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${C_YELLOW}[DRY-RUN]${C_RESET} $@"
    else
        eval "$@"
    fi
}

log_header() { echo -e "\n${C_BOLD}${C_BLUE}[$1] $2${C_RESET}"; }

# --- Start ---
echo -e "${C_BOLD}==================================================${C_RESET}"
echo -e "${C_BOLD}  Smart System Update (v3.2)                  ${C_RESET}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${C_YELLOW}  *** DRY RUN MODE ***                        ${C_RESET}"
fi
echo -e "${C_BOLD}==================================================${C_RESET}"
sleep 1

# --- 1. APT ---
log_header "1/4" "Handling APT packages..."

run_cmd "apt-get update -y"

if [ "$FULL_UPGRADE" = true ]; then
    echo "-> Running 'apt dist-upgrade'..."
    run_cmd "apt-get dist-upgrade -y"
else
    echo "-> Running 'apt upgrade'..."
    run_cmd "apt-get upgrade -y"
    
    # Check for held back packages (only relevant if not doing dist-upgrade)
    if [ "$DRY_RUN" = false ]; then
        echo "-> Checking for phased/held packages..."
        UPGRADABLE=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}' | xargs)
        if [ -n "$UPGRADABLE" ]; then
             echo -e "   ${C_YELLOW}Held back: $UPGRADABLE${C_RESET}"
             echo "   -> Installing held packages..."
             run_cmd "apt-get install -y $UPGRADABLE"
        fi
    fi
fi

echo "-> Cleaning up..."
run_cmd "apt-get autoremove --purge -y"

# --- 2. Snap ---
log_header "2/4" "Handling Snap packages..."
if command -v snap &>/dev/null; then
    run_cmd "snap refresh"
else
    echo "Snap not installed."
fi

# --- 3. Flatpak ---
log_header "3/4" "Handling Flatpak packages..."
if command -v flatpak &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would update flatpaks."
    else
        if ! flatpak update -y; then
             echo -e "   ${C_YELLOW}Update failed, attempting repair...${C_RESET}"
             flatpak repair
             flatpak update -y
        fi
    fi
else
    echo "Flatpak not installed."
fi

# --- 4. Firmware ---
log_header "4/4" "Handling Firmware updates..."
if command -v fwupdmgr &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
         echo "  [DRY-RUN] Would check and update firmware."
    else
         echo "-> Checking for updates..."
         # fwupdmgr get-updates returns 2 if no updates, 0 if success, 1 if error
         if fwupdmgr get-updates; then
             echo "-> Applying updates..."
             fwupdmgr update -y || true
         else
             code=$?
             if [ $code -eq 2 ]; then
                 echo "-> No firmware updates available."
             else
                 echo -e "${C_YELLOW}-> Firmware check returned code $code (ignoring).${C_RESET}"
             fi
         fi
    fi
else
    echo "fwupdmgr not installed."
fi

# --- Final ---
echo -e "\n${C_BOLD}${C_GREEN}✅ Update complete!${C_RESET}"

if [ -f /var/run/reboot-required ]; then
    echo -e "${C_RED}${C_BOLD}*** REBOOT REQUIRED ***${C_RESET}"
fi
