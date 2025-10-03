#!/bin/bash

# ==============================================================================
# System Cleanup Script for Ubuntu-based Systems
# Author: Azzar Budiyanto (via FREA), Refined by Gemini
# Version: 3.1
#
# Deep cleanup for APT, Snap, Flatpak, Docker, temp files, logs,
# user-level cache, broken symlinks, orphaned packages, and more.
# Also tracks total disk space freed.
#
# Refinements in v3.1:
# - Added colorized output for better readability.
# - Fixed a bug in the final report section.
# - Silenced verbose command output for a cleaner log.
# ==============================================================================

# --- Color Definitions ---
C_RESET='[0m'
C_GREEN='[0;32m'
C_YELLOW='[0;33m'
C_BLUE='[0;34m'
C_BOLD='[1m'

# --- Script settings for robustness ---
set -e
set -o pipefail

# --- Auto-elevate to root if not already ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${C_YELLOW}This script requires root privileges. Attempting to re-run with sudo...${C_RESET}"
    # Re-execute the script with sudo, passing along all original arguments.
    exec sudo "$0" "$@"
    exit $? # This exit is technically unreachable due to exec, but good practice.
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

echo -e "${C_BOLD}System Cleanup Initializing (v3.1)...${C_RESET}"
echo "Target user for cache cleaning: $SUDO_USER_NAME"
echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

initial_space=$(get_available_space)
echo -e "${C_BOLD}Disk usage before cleanup:${C_RESET}"
df -h /
echo -e "${C_BOLD}-------------------------------------------${C_RESET}"
sleep 1

# --- [1] APT Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[1/7] Cleaning package manager (APT) cache...${C_RESET}"
apt-get clean -y >/dev/null 2>&1
apt-get autoremove --purge -y >/dev/null 2>&1
apt-get autoclean -y >/dev/null 2>&1

# Remove leftover config files from uninstalled packages
echo "  >> Purging leftover configuration files..."
dpkg -l | awk '/^rc/ { print $2 }' | xargs -r apt-get purge -y >/dev/null 2>&1
echo -e "${C_GREEN}APT cache and leftover packages cleaned.${C_RESET}"

# --- [2] Modern Package Formats ---
echo -e "\n${C_BOLD}${C_BLUE}[2/7] Cleaning Docker, Snap, and Flatpak...${C_RESET}"

# Docker
if command -v docker &>/dev/null; then
    echo "  >> Cleaning Docker system..."
    docker system prune -af >/dev/null 2>&1
    echo -e "${C_GREEN}Docker has been cleaned.${C_RESET}"
else
    echo -e "${C_YELLOW}Info: Docker is not installed.${C_RESET}"
fi

# Snap (Safe version)
if command -v snap &>/dev/null; then
    echo "  >> Cleaning Snap packages..."
    # Removes disabled snap revisions
    snap list --all | awk '/disabled/{print $1, $3}' |
        while read -r snapname revision; do
            snap remove "$snapname" --revision="$revision" >/dev/null 2>&1
        done
    # Clean snap system cache
    rm -rf /var/cache/snapd/
    echo -e "${C_GREEN}Snap cache and old versions cleaned.${C_RESET}"
else
    echo -e "${C_YELLOW}Info: Snap is not installed.${C_RESET}"
fi

# Flatpak (Safe version)
if command -v flatpak &>/dev/null; then
    echo "  >> Cleaning Flatpak packages..."
    flatpak uninstall --unused -y >/dev/null 2>&1
    echo -e "${C_GREEN}Unused Flatpak runtimes cleaned.${C_RESET}"
else
    echo -e "${C_YELLOW}Info: Flatpak is not installed.${C_RESET}"
fi

# --- [3] System Logs & Temporary Files ---
echo -e "\n${C_BOLD}${C_BLUE}[3/7] Cleaning logs and temporary files...${C_RESET}"

# Combine find operations for efficiency
find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" \) -delete
journalctl --vacuum-time=2weeks >/dev/null 2>&1
find /tmp -type f -mtime +7 -delete
find /var/tmp -type f -mtime +7 -delete
echo -e "${C_GREEN}Logs and temporary files have been cleaned.${C_RESET}"

# --- [4] User-Level Caches ---
echo -e "\n${C_BOLD}${C_BLUE}[4/7] Cleaning application caches and trash for $SUDO_USER_NAME...${C_RESET}"

if [ -d "$USER_HOME" ]; then
    # Note: Clearing .cache is generally safe but aggressive.
    rm -rf "$USER_HOME/.cache/"* &>/dev/null
    rm -rf "$USER_HOME/.local/share/Trash/files/"* &>/dev/null
    rm -rf "$USER_HOME/.local/share/Trash/info/"* &>/dev/null
    rm -rf "$USER_HOME/.thumbnails/"* &>/dev/null
    rm -f "$USER_HOME/.recently-used.xbel" &>/dev/null
    rm -f "$USER_HOME/.config/gtk-3.0/bookmarks" &>/dev/null
    
    echo -e "${C_GREEN}Cache and trash for user $SUDO_USER_NAME have been cleaned.${C_RESET}"
else
    echo -e "${C_YELLOW}Warning: Could not find home directory for $SUDO_USER_NAME. Skipping user cache.${C_RESET}"
fi

# --- [5] Broken Symlinks Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[5/7] Cleaning broken symbolic links...${C_RESET}"

clean_symlinks_safe() {
    local dir="$1"
    local timeout_duration="${2:-30s}"
    if [ ! -d "$dir" ]; then
        echo -e "  ${C_YELLOW}>> Directory not found, skipping: $dir${C_RESET}"
        return
    fi

    echo "  >> Checking: $dir (Timeout: $timeout_duration)"
    if ! timeout "$timeout_duration" find "$dir" -xtype l -delete; then
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo -e "  ${C_YELLOW}!! Timeout reached while checking $dir. It might be a large or slow directory.${C_RESET}"
        else
            echo -e "  ${C_YELLOW}!! An error occurred (code: $exit_code) while checking $dir.${C_RESET}"
        fi
    fi
}

# Scan user and common system directories
if [ -d "$USER_HOME" ]; then
    clean_symlinks_safe "$USER_HOME" "2m" # Longer timeout for home directory
fi
clean_symlinks_safe "/etc" "1m"
clean_symlinks_safe "/var" "1m"
clean_symlinks_safe "/usr/local" "1m"
clean_symlinks_safe "/root"

echo -e "${C_GREEN}Broken symlink cleanup finished.${C_RESET}"

# --- [6] Old Kernel Cleanup (Safer Method) ---
echo -e "\n${C_BOLD}${C_BLUE}[6/7] Cleaning old Linux kernels...${C_RESET}"

running_kernel=$(uname -r)
installed_images=$(dpkg-query -W -f='${Package}
' 'linux-image-[0-9]*' 2>/dev/null | grep -- '-generic$' || true)

if [ -n "$installed_images" ]; then
    latest_image=$(echo "$installed_images" | sort -V | tail -n 1)
    running_image="linux-image-${running_kernel}"
    
    packages_to_purge=""
    for image in $installed_images; do
        if [[ "$image" != "$running_image" && "$image" != "$latest_image" ]]; then
            version=$(echo "$image" | sed 's/linux-image-//')
            packages_to_purge="$packages_to_purge $image linux-headers-$version linux-modules-$version"
        fi
    done
    
    packages_to_purge=$(echo "$packages_to_purge" | xargs)

    if [ -n "$packages_to_purge" ]; then
        echo "  >> Found old kernel packages to purge. This may take a moment."
        apt-get remove --purge -y $packages_to_purge >/dev/null 2>&1
        echo -e "  ${C_GREEN}>> Old kernel packages have been removed.${C_RESET}"
    else
        echo "  >> No old kernels to remove. System is up to date."
    fi
else
    echo "  >> Could not determine installed kernels or none are 'generic'."
fi

# --- [7] Orphaned Package Cleanup ---
echo -e "\n${C_BOLD}${C_BLUE}[7/7] Removing orphaned packages...${C_RESET}"

if command -v deborphan &>/dev/null; then
    deborphan | xargs -r apt-get remove --purge -y >/dev/null 2>&1 || true
    echo -e "${C_GREEN}Orphaned packages successfully removed.${C_RESET}"
else
    echo -e "${C_YELLOW}Info: deborphan is not installed, skipping. (Hint: sudo apt install deborphan)${C_RESET}"
fi
echo -e "${C_BOLD}-------------------------------------------${C_RESET}"

# --- Final Report ---
final_space=$(get_available_space)
cleaned_space=$((final_space - initial_space))

echo -e "\n${C_BOLD}${C_GREEN}✅ System cleanup complete!${C_RESET}"
echo -e "\n${C_BOLD}Disk usage after cleanup:${C_RESET}"
df -h /
echo
echo -e "${C_BOLD}===========================================${C_RESET}"
if ((cleaned_space > 0)); then
    echo -e " ${C_BOLD}Total Disk Space Freed: ${C_GREEN}$(format_bytes $cleaned_space)${C_RESET}"
else
    echo -e " ${C_YELLOW}No significant disk space was freed.${C_RESET}"
fi
echo -e "${C_BOLD}===========================================${C_RESET}"