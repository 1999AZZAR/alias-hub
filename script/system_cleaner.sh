#!/bin/bash

# ==============================================================================
# System Cleanup Script for Linux
# Author: Azzar Budiyanto (via FREA), Refined by Gemini
# Version: 3.2
#
# Deep cleanup for APT, Snap, Flatpak, Docker, temp files, logs,
# user-level cache (safe mode), broken symlinks, and old kernels.
# ==============================================================================

# --- Script settings ---
set -e
set -o pipefail
export LC_NUMERIC=C

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'

# --- Variables ---
DRY_RUN=false

# --- Usage / Help ---
usage() {
    echo -e "${C_BOLD}Usage:${C_RESET} $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -d, --dry-run    Simulate cleanup without deleting files."
    echo "  -h, --help       Show this help message."
    echo
    exit 0
}

# --- Parse Arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo -e "${C_RED}Unknown parameter passed: $1${C_RESET}"; usage ;;
    esac
    shift
done

# --- Auto-elevate to root ---
if [[ $EUID -ne 0 ]]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${C_YELLOW}Dry run: running without root. Some steps might fail.${C_RESET}"
    else
        echo -e "${C_YELLOW}This script requires root privileges. Attempting to re-run with sudo...${C_RESET}"
        exec sudo "$0" "$@"
        exit $?
    fi
fi

# --- Helper Functions ---
log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[OK]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${C_YELLOW}[DRY-RUN]${C_RESET} $@"
    else
        eval "$@"
    fi
}

get_available_space() {
    df --output=avail -B1 / | tail -n 1
}

format_bytes() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes} B"
    elif ((bytes < 1048576)); then
        printf "%.2f KB" "$(bc -l <<< "$bytes / 1024")"
    elif ((bytes < 1073741824)); then
        printf "%.2f MB" "$(bc -l <<< "$bytes / 1048576")"
    else
        printf "%.2f GB" "$(bc -l <<< "$bytes / 1073741824")"
    fi
}

# --- Initialization ---
SUDO_USER_NAME=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd "$SUDO_USER_NAME" | cut -d: -f6)

echo -e "${C_BOLD}System Cleanup Initializing (v3.2)...${C_RESET}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${C_YELLOW}*** DRY RUN MODE ACTIVE: No changes will be made ***${C_RESET}"
fi
echo "Target user for cache cleaning: $SUDO_USER_NAME"
echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

initial_space=$(get_available_space)

# --- [1] APT Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[1/7] Cleaning package manager (APT) cache...${C_RESET}"
run_cmd "apt-get clean -y >/dev/null 2>&1"
run_cmd "apt-get autoremove --purge -y >/dev/null 2>&1"
run_cmd "apt-get autoclean -y >/dev/null 2>&1"

# Purge configs
if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] Would purge leftover config files."
else
    echo "  >> Purging leftover configuration files..."
    leftover_packages=$(dpkg -l | awk '/^rc/ { print $2 }')
    if [ -n "$leftover_packages" ]; then
        echo "$leftover_packages" | xargs -r apt-get purge -y >/dev/null 2>&1
        log_success "Purged config files."
    else
        log_info "No leftover config files found."
    fi
fi

# --- [2] Modern Package Formats ---
echo -e "\n${C_BOLD}${C_BLUE}[2/7] Cleaning Docker, Snap, and Flatpak...${C_RESET}"

# Docker
if command -v docker &>/dev/null; then
    run_cmd "docker system prune -af >/dev/null 2>&1"
    log_success "Docker cleaned."
else
    log_info "Docker not installed."
fi

# Snap
if command -v snap &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would clean snap cache."
    else
        # Simplified cleaning for brevity in script
        snap list --all | awk '/disabled/{print $1, $3}' | \
            while read -r snapname revision; do
                snap remove "$snapname" --revision="$revision" >/dev/null 2>&1
            done
        rm -rf /var/cache/snapd/
        log_success "Snap cleaned."
    fi
else
    log_info "Snap not installed."
fi

# Flatpak
if command -v flatpak &>/dev/null; then
    run_cmd "flatpak uninstall --unused -y >/dev/null 2>&1"
    log_success "Flatpak cleaned."
else
    log_info "Flatpak not installed."
fi

# --- [3] System Logs & Temporary Files ---
echo -e "\n${C_BOLD}${C_BLUE}[3/7] Cleaning logs and temporary files...${C_RESET}"

if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] Would delete old logs and tmp files."
else
    find /var/log -type f \( -name \"*.gz\" -o -name \"*.1\" -o -name \"*.old\" \) -delete 2>/dev/null || true
    journalctl --vacuum-time=2weeks >/dev/null 2>&1 || true
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true
    log_success "Logs and temp files cleaned."
fi

# --- [4] User-Level Caches (Safer) ---
echo -e "\n${C_BOLD}${C_BLUE}[4/7] Cleaning specific user caches for $SUDO_USER_NAME...${C_RESET}"

if [ -d "$USER_HOME" ]; then
    targets=(
        "$USER_HOME/.cache/thumbnails"
        "$USER_HOME/.local/share/Trash"
        "$USER_HOME/.cache/pip"
        "$USER_HOME/.npm/_cacache"
    )

    for target in "${targets[@]}"; do
        if [ -d "$target" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [DRY-RUN] Would remove: $target"
            else
                rm -rf "$target"/* 2>/dev/null || true
            fi
        fi
    done
    log_success "User trash and thumbnails cleaned."
else
    log_warn "User home directory not found."
fi

# --- [5] Broken Symlinks Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[5/7] Cleaning broken symbolic links...${C_RESET}"

clean_symlinks_safe() {
    local dir="$1"
    if [ ! -d "$dir" ]; then return; fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Checking $dir for broken links..."
    else
        find "$dir" -xtype l -delete 2>/dev/null || true
    fi
}

clean_symlinks_safe "$USER_HOME"
clean_symlinks_safe "/etc"
clean_symlinks_safe "/var"
clean_symlinks_safe "/usr/local"

log_success "Symlinks cleaned."

# --- [6] Old Kernel Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[6/7] Cleaning old Linux kernels...${C_RESET}"

if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] Would remove old kernels."
else
    run_cmd "apt-get autoremove --purge -y >/dev/null 2>&1"
    log_info "Performed apt autoremove to clean kernels."
fi

# --- [7] Orphaned Packages ---
echo -e "\n${C_BOLD}${C_BLUE}[7/7] Removing orphaned packages...${C_RESET}"

if command -v deborphan &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would run deborphan."
    else
        deborphan | xargs -r apt-get remove --purge -y >/dev/null 2>&1 || true
        log_success "Deborphan cleanup done."
    fi
else
    log_info "Deborphan not installed. Skipping."
fi

echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

# --- Final Report ---
final_space=$(get_available_space)
cleaned_space=$((final_space - initial_space))

echo -e "\n${C_BOLD}${C_GREEN}✅ System cleanup complete!${C_RESET}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${C_YELLOW}(Dry run: No actual space freed)${C_RESET}"
else
    if ((cleaned_space > 0)); then
        echo -e " ${C_BOLD}Total Disk Space Freed: ${C_GREEN}$(format_bytes $cleaned_space)${C_RESET}"
    else
        echo -e " ${C_YELLOW}No significant disk space was freed.${C_RESET}"
    fi
fi
echo -e "${C_BOLD}===========================================${C_RESET}"