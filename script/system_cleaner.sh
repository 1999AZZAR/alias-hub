#!/bin/bash

# ==============================================================================
# System Cleanup Script for Linux
# Author: Azzar Budiyanto (via FREA)
# Version: 4.1
#
# Deep cleanup for APT, Snap, Flatpak, Docker, temp files, logs,
# user-level cache (safe mode), broken symlinks, and old kernels.
# Optimized for timeout resistance and robust error handling.
#
# Environment Variables:
#   SKIP_FLATPAK=1    Skip Flatpak cleanup entirely (useful if it hangs)
# ==============================================================================

# --- Script settings ---
set -o pipefail
export LC_NUMERIC=C

# Global timeout for entire script (15 minutes)
SCRIPT_TIMEOUT=900

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
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${C_YELLOW}[DRY-RUN]${C_RESET} $*"
    else
        "$@" || { log_warn "Command failed (non-critical): $*"; return 1; }
    fi
}

safe_timeout() {
    local duration=$1
    shift
    timeout "$duration" "$@" || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_warn "Operation timed out after ${duration}s: $*"
        else
            log_warn "Operation failed: $*"
        fi
        return $exit_code
    }
}

wait_for_apt_lock() {
    local max_wait=60
    local waited=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        if [ $waited -ge $max_wait ]; then
            log_error "APT is locked by another process. Waited ${max_wait}s. Skipping APT operations."
            return 1
        fi
        log_info "Waiting for APT lock to be released... (${waited}s/${max_wait}s)"
        sleep 5
        waited=$((waited + 5))
    done
    return 0
}

get_available_space() {
    df --output=avail -B1 / | tail -n 1
}

format_bytes() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes} B"
    elif ((bytes < 1048576)); then
        awk -v b="$bytes" 'BEGIN { printf "%.2f KB", b / 1024 }'
    elif ((bytes < 1073741824)); then
        awk -v b="$bytes" 'BEGIN { printf "%.2f MB", b / 1048576 }'
    else
        awk -v b="$bytes" 'BEGIN { printf "%.2f GB", b / 1073741824 }'
    fi
}

# --- Initialization ---
SUDO_USER_NAME=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd "$SUDO_USER_NAME" 2>/dev/null | cut -d: -f6)

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    log_warn "Could not determine user home directory. Some operations may be skipped."
    USER_HOME=""
fi

echo -e "${C_BOLD}System Cleanup Initializing (v4.1)...${C_RESET}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${C_YELLOW}*** DRY RUN MODE ACTIVE: No changes will be made ***${C_RESET}"
fi
if [ "${SKIP_FLATPAK:-0}" = "1" ]; then
    echo -e "${C_YELLOW}*** Flatpak cleanup disabled (SKIP_FLATPAK=1) ***${C_RESET}"
fi
echo "Target user for cache cleaning: $SUDO_USER_NAME"
echo "User home directory: ${USER_HOME:-N/A}"
echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

initial_space=$(get_available_space)

# --- [1] APT Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[1/7] Cleaning package manager (APT) cache...${C_RESET}"

if ! wait_for_apt_lock; then
    log_warn "Skipping APT operations due to lock timeout."
else
    safe_timeout 300 apt-get clean -y >/dev/null 2>&1 && log_success "APT clean completed."
    safe_timeout 300 apt-get autoremove --purge -y >/dev/null 2>&1 && log_success "APT autoremove completed."
    safe_timeout 300 apt-get autoclean -y >/dev/null 2>&1 && log_success "APT autoclean completed."

    # Purge configs
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would purge leftover config files."
    else
        echo "  >> Purging leftover configuration files..."
        leftover_packages=$(dpkg -l | awk '/^rc/ { print $2 }')
        if [ -n "$leftover_packages" ]; then
            echo "$leftover_packages" | xargs -r timeout 180 apt-get purge -y >/dev/null 2>&1 && \
                log_success "Purged config files." || \
                log_warn "Some config files could not be purged."
        else
            log_info "No leftover config files found."
        fi
    fi
fi

# --- [2] Modern Package Formats ---
echo -e "\n${C_BOLD}${C_BLUE}[2/7] Cleaning Docker, Snap, and Flatpak...${C_RESET}"

# Docker
if command -v docker &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would run docker system prune."
    else
        echo "  >> Cleaning Docker system..."
        safe_timeout 180 docker system prune -af --volumes >/dev/null 2>&1 && \
            log_success "Docker cleaned." || \
            log_warn "Docker cleanup incomplete or timed out."
    fi
else
    log_info "Docker not installed."
fi

# Snap
if command -v snap &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would clean snap cache."
    else
        echo "  >> Removing old snap revisions..."
        snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            timeout 30 snap remove "$snapname" --revision="$revision" >/dev/null 2>&1 || \
                log_warn "Failed to remove $snapname revision $revision"
        done
        if [ -d /var/cache/snapd ]; then
            rm -rf /var/cache/snapd/* 2>/dev/null || log_warn "Could not clear snap cache."
        fi
        log_success "Snap cleaned."
    fi
else
    log_info "Snap not installed."
fi

# Flatpak
if command -v flatpak &>/dev/null; then
    if [ "${SKIP_FLATPAK:-0}" = "1" ]; then
        log_info "Flatpak cleanup skipped (SKIP_FLATPAK=1)"
    elif [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would clean Flatpak (system + user scopes)."
    else
        echo "  >> Cleaning system flatpaks..."
        # Skip repair - it often hangs. Just remove unused packages with aggressive timeout.
        timeout --kill-after=5 15 flatpak uninstall --unused --system -y --noninteractive >/dev/null 2>&1 || \
            log_warn "Flatpak system cleanup timed out or failed."

        if [ -n "$SUDO_USER_NAME" ] && id "$SUDO_USER_NAME" >/dev/null 2>&1; then
            echo "  >> Cleaning user flatpaks for $SUDO_USER_NAME..."
            sudo -u "$SUDO_USER_NAME" bash -c "timeout --kill-after=5 15 flatpak uninstall --unused --user -y --noninteractive >/dev/null 2>&1" || \
                log_warn "Flatpak user cleanup timed out or failed."
        fi

        log_success "Flatpak cleaned (system + user)."
    fi
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

if [ -n "$USER_HOME" ] && [ -d "$USER_HOME" ]; then
    targets=(
        "$USER_HOME/.cache/thumbnails"
        "$USER_HOME/.local/share/Trash"
        "$USER_HOME/.cache/pip"
        "$USER_HOME/.cache/fontconfig"
        "$USER_HOME/.cache/yarn"
        "$USER_HOME/.npm/_cacache"
    )

    for target in "${targets[@]}"; do
        if [ -d "$target" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [DRY-RUN] Would remove: $target"
            else
                rm -rf "$target"/* 2>/dev/null || log_warn "Could not fully clean $target"
            fi
        fi
    done
    log_success "User cache and trash cleaned."
else
    log_warn "User home directory not accessible. Skipping user cache cleanup."
fi

# --- [5] Broken Symlinks Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[5/7] Cleaning broken symbolic links (30s timeout per dir)...${C_RESET}"

clean_symlinks_safe() {
    local dir="$1"
    local maxdepth="${2:-10}"
    if [ ! -d "$dir" ]; then 
        log_warn "Directory $dir not found, skipping."
        return 1
    fi
    
    echo "  >> Checking $dir (max depth: $maxdepth)..."
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] find \"$dir\" -maxdepth $maxdepth -xdev -xtype l"
    else
        local count
        count=$(timeout 30 find "$dir" -maxdepth "$maxdepth" -xdev -xtype l -ignore_readdir_race -delete -print 2>/dev/null | wc -l) || {
            log_warn "Scan for $dir timed out or encountered issues."
            return 1
        }
        if [ "$count" -gt 0 ]; then
            log_info "Removed $count broken symlink(s) from $dir"
        fi
    fi
}

# Scan with limited depth to prevent hangs
clean_symlinks_safe "$USER_HOME" 6
clean_symlinks_safe "/etc" 5
clean_symlinks_safe "/var" 5
clean_symlinks_safe "/usr/local" 5

log_success "Symlinks cleanup process finished."

# --- [6] Old Kernel Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[6/7] Cleaning old Linux kernels...${C_RESET}"

if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] Would remove old kernels."
else
    if wait_for_apt_lock; then
        safe_timeout 300 apt-get autoremove --purge -y >/dev/null 2>&1 && \
            log_success "Performed apt autoremove to clean kernels." || \
            log_warn "Kernel cleanup incomplete."
    else
        log_warn "APT locked, skipping kernel cleanup."
    fi
fi

# --- [7] Orphaned Packages ---
echo -e "\n${C_BOLD}${C_BLUE}[7/7] Removing orphaned packages...${C_RESET}"

if command -v deborphan &>/dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would run deborphan."
    else
        if wait_for_apt_lock; then
            orphans=$(deborphan 2>/dev/null)
            if [ -n "$orphans" ]; then
                echo "$orphans" | xargs -r timeout 180 apt-get remove --purge -y >/dev/null 2>&1 && \
                    log_success "Deborphan cleanup done." || \
                    log_warn "Some orphaned packages could not be removed."
            else
                log_info "No orphaned packages found."
            fi
        else
            log_warn "APT locked, skipping deborphan."
        fi
    fi
else
    log_info "Deborphan not installed. Skipping."
fi

echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

# --- Final Report ---
final_space=$(get_available_space)
cleaned_space=$((final_space - initial_space))

echo -e "\n${C_BOLD}${C_GREEN}System cleanup complete!${C_RESET}"
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
