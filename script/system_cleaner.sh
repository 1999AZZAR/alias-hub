#!/bin/bash

# ==============================================================================
# System Cleanup Script for Ubuntu-based Systems
# Author: Azzar Budiyanto (via FREA), Refined by Gemini
# Version: 2.7
#
# Deep cleanup for APT, Snap, Flatpak, Docker, temp files, logs,
# user-level cache, broken symlinks, orphaned packages, and more.
# Also tracks total disk space freed.
# ==============================================================================

# --- Auto-elevate to root if not already ---
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Attempting to re-run with sudo..."
    # Re-execute the script with sudo, passing along all original arguments.
    sudo "$0" "$@"
    # Exit the original, non-privileged script with the exit code of the sudo command.
    exit $?
fi

# --- Helper Functions ---
get_available_space() {
    df --output=avail -B1 / | tail -n 1
}

format_bytes() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes} B"
    elif ((bytes < 1048576)); then
        printf "%.2f KB" $(echo "$bytes / 1024" | bc -l)
    elif ((bytes < 1073741824)); then
        printf "%.2f MB" $(echo "$bytes / 1048576" | bc -l)
    else
        printf "%.2f GB" $(echo "$bytes / 1073741824" | bc -l)
    fi
}

# --- Safety Check ---
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    exit 1
fi

SUDO_USER_NAME=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd "$SUDO_USER_NAME" | cut -d: -f6)

echo "System Cleanup Initializing (v2.7)..."
echo "Target user: $SUDO_USER_NAME"
echo "-------------------------------------------"

initial_space=$(get_available_space)
echo "Disk usage before cleanup:"
df -h /
echo "-------------------------------------------"
sleep 2

# --- [1] APT Cleanup ---
echo "[1/6] Cleaning package manager (APT) cache..."
apt-get clean -y >/dev/null
apt-get autoremove --purge -y >/dev/null
apt-get autoclean -y >/dev/null

# Remove leftover config
dpkg -l | awk '/^rc/ { print $2 }' | xargs -r apt-get purge -y >/dev/null
echo "APT cache and leftover packages cleaned."
echo

# --- [2] Modern Package Formats ---
echo "[2/6] Cleaning Docker, Snap, and Flatpak..."

# Docker
if command -v docker &>/dev/null; then
    docker system prune -af >/dev/null
    echo "Docker has been cleaned."
else
    echo "Info: Docker is not installed."
fi

# Snap
if command -v snap &>/dev/null; then
    snap list --all | awk '/disabled/{print $1, $3}' |
        while read snapname revision; do
            snap remove "$snapname" --revision="$revision" >/dev/null
        done
    rm -rf /var/cache/snapd/ ~/snap
    echo "Snap cache and old versions cleaned."
else
    echo "Info: Snap is not installed."
fi

# Flatpak
if command -v flatpak &>/dev/null; then
    flatpak uninstall --unused -y >/dev/null
    rm -rf ~/.var/app/*
    echo "Unused Flatpak runtimes cleaned."
else
    echo "Info: Flatpak is not installed."
fi
echo "-------------------------------------------"
sleep 1

# --- [3] System Logs & Temporary Files ---
echo "[3/6] Cleaning logs and temporary files..."

find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete
find /var/log -type f -name "*.old" -delete
journalctl --vacuum-time=2weeks >/dev/null
find /tmp -type f -mtime +7 -delete
find /var/tmp -type f -mtime +7 -delete
echo "Logs and temporary files have been cleaned."
echo

# --- [4] User-Level Caches ---
echo "[4/6] Cleaning application caches and trash..."

if [ -d "$USER_HOME" ]; then
    rm -rf "$USER_HOME/.local/share/Trash/files/"* &>/dev/null
    rm -rf "$USER_HOME/.local/share/Trash/info/"* &>/dev/null
    rm -rf "$USER_HOME/.cache/"* &>/dev/null
    rm -rf "$USER_HOME/.recently-used.xbel" &>/dev/null
    rm -rf "$USER_HOME/.thumbnails" "$USER_HOME/.cache/thumbnails" &>/dev/null
    rm -rf "$USER_HOME/.config/gtk-3.0/bookmarks" &>/dev/null
    echo "Cache and trash for user $SUDO_USER_NAME have been cleaned."
else
    echo "Warning: Could not find home directory for $SUDO_USER_NAME."
fi
echo

# --- [5] Broken Symlinks & Old Kernels ---
echo "[5/6] Cleaning broken symlinks and old kernels..."

# --- Smart & Silent Broken Symlink Cleaner with Timeout ---
clean_symlinks_safe() {
    local dir="$1"
    local timeout_duration="30s" # Set a reasonable timeout
    if [ ! -d "$dir" ]; then return; fi

    echo "  >> Checking: $dir (Timeout: $timeout_duration)"

    # Use the timeout command to prevent the find operation from hanging
    timeout "$timeout_duration" find "$dir" -xtype l -delete 2>/dev/null
    local exit_code=$?

    # Check if the command timed out (exit code 124)
    if [[ $exit_code -eq 124 ]]; then
        echo "  !! Timeout reached while checking $dir. Skipping this directory."
    fi
}

# Scan each subdirectory in home
if [ -d "$USER_HOME" ]; then
    for sub in "$USER_HOME"/*; do
        if [ -d "$sub" ]; then # Ensure it's a directory
            clean_symlinks_safe "$sub"
        fi
    done
else
    echo "Warning: Home directory $USER_HOME not found, skipping symlink check."
fi

# Clean root directory
clean_symlinks_safe "/root"

# --- Kernel Cleanup ---
current_kernel=$(uname -r | cut -d'-' -f1,2)
dpkg -l 'linux-image-*' | grep ^ii | grep -v "$current_kernel" |
    awk '{print $2}' | xargs -r apt-get purge -y >/dev/null

echo "Old kernels and broken symlinks have been removed."
echo

# --- [6] Orphaned Package Cleanup ---
echo "[6/6] Removing orphaned packages..."

if command -v deborphan &>/dev/null; then
    deborphan | xargs -r apt-get remove --purge -y >/dev/null
    echo "Orphaned packages successfully removed."
else
    echo "Info: deborphan is not installed, skipping."
fi
echo "-------------------------------------------"

# --- Final Report ---
final_space=$(get_available_space)
cleaned_space=$((final_space - initial_space))

echo "✅ System cleanup complete!"
echo
echo "Disk usage after cleanup:"
df -h /
echo
echo "==========================================="
echo " Total Disk Space Freed: $(format_bytes $cleaned_space)"
echo "==========================================="
