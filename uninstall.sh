#!/bin/bash

# ==============================================================================
# ALIAS HUB UNINSTALLATION SCRIPT
# ==============================================================================
#
# Removes Alias Hub and restores original system configurations.
#
# FEATURES:
# - Shell configuration cleanup (bash, zsh, fish, ash, dash)
# - Configuration file restoration (neofetch, fastfetch)
# - Repository directory removal
# - Dry-run mode support
# - Colorized output and logging
#
# ==============================================================================

set -euo pipefail

# --- Configuration ---
readonly ALIASES_DIR="$HOME/alias-hub"
readonly BACKUP_PATTERN=".alias-hub-backup.*"

# --- Global Variables ---
DRY_RUN=false
VERBOSE=false
CURRENT_SHELL=""
SHELL_RC=""

# --- Color Codes ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# --- Helper Functions ---
print_info() { echo -e "${BLUE}INFO:${NC} $1"; }
print_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${NC} $1"; }
print_error() { echo -e "${RED}ERROR:${NC} $1" >&2; exit 1; }

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}DEBUG:${NC} $1"
    fi
}

detect_shell() {
    print_verbose "Detecting shell..."
    # Get the current shell, fallback to $SHELL if needed
    CURRENT_SHELL="${CURRENT_SHELL:-$SHELL}"
    CURRENT_SHELL="${CURRENT_SHELL:-$(ps -p $$ -o cmd= | awk '{print $1}')}"

    # Extract basename
    CURRENT_SHELL="${CURRENT_SHELL##*/}"

    case "$CURRENT_SHELL" in
        bash) SHELL_RC="$HOME/.bashrc" ;;
        zsh)  SHELL_RC="$HOME/.zshrc" ;;
        fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
        ash|dash) SHELL_RC="$HOME/.profile" ;;
        *) print_warning "Unsupported shell: $CURRENT_SHELL. Manual cleanup may be required." ;;
    esac
}

restore_backup() {
    local file="$1"
    # Find the latest backup file
    local latest_backup=$(ls -t "${file}".alias-hub-backup.* 2>/dev/null | head -n 1)

    if [[ -n "$latest_backup" ]]; then
        print_info "Restoring backup: $(basename "$latest_backup") -> $(basename "$file")"
        if [[ "$DRY_RUN" == false ]]; then
            mv "$latest_backup" "$file"
            # Remove any other backups for this file
            rm -f "${file}".alias-hub-backup.* 2>/dev/null || true
        fi
    else
        print_verbose "No backup found for $file"
    fi
}

show_help() {
    cat << EOF
Alias Hub Uninstaller

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help      Show this help message
    --dry-run   Show what would be done without making changes
    --verbose   Enable verbose output

EOF
}

# --- Main Logic ---

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help) show_help; exit 0 ;;
            --dry-run) DRY_RUN=true; VERBOSE=true ;;
            --verbose) VERBOSE=true ;;
            *) print_error "Unknown option: $1" ;;
        esac
        shift
    done
}

main() {
    parse_arguments "$@"

    echo "========================================"
    echo "      Alias Hub Uninstaller"
    echo "========================================"
    echo

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN MODE - No changes will be made"
        echo
    fi

    detect_shell

    # 1. Remove from Shell RC
    if [[ -f "$SHELL_RC" ]]; then
        if grep -q "Alias Hub Configuration" "$SHELL_RC"; then
            print_info "Removing configuration from $SHELL_RC"
            if [[ "$DRY_RUN" == false ]]; then
                sed -i '/# --- Alias Hub Configuration ---/,/# --- End Alias Hub Configuration ---/d' "$SHELL_RC"
            fi
            print_success "Shell configuration cleaned"
        else
            print_info "No Alias Hub configuration found in $SHELL_RC"
        fi
    fi

    # 2. Restore Backups
    print_info "Restoring original configurations..."
    restore_backup "$HOME/.config/neofetch/config.conf"
    restore_backup "$HOME/.config/fastfetch/config.jsonc"

    # 3. Remove Repository
    if [[ -d "$ALIASES_DIR" ]]; then
        print_info "Removing Alias Hub directory: $ALIASES_DIR"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$ALIASES_DIR"
        fi
        print_success "Directory removed"
    fi

    echo
    print_success "Alias Hub has been successfully uninstalled."
    print_info "Please restart your terminal or run 'source $SHELL_RC' to apply changes."
}

main "$@"
