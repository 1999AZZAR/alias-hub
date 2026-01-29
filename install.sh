#!/bin/bash

# ==============================================================================
# ALIAS HUB INSTALLATION SCRIPT
# ==============================================================================
#
# Comprehensive installation and configuration script for the Alias Hub collection
# This script provides a seamless setup experience for enhanced terminal productivity
#
# FILE INFORMATION:
# - Location: install.sh (root directory)
# - Type: Bash installation script
# - Compatibility: Linux systems with standard package managers
# - Dependencies: bash 4+, git, curl, sudo access for package installation
#
# FEATURES:
# - Multi-package manager support (apt, dnf, pacman, apk, zypper, emerge)
# - Multi-shell support (bash, zsh, fish, ash, dash)
# - Intelligent environment detection
# - Safe installation with automatic backups
# - Comprehensive configuration file management
# - Uninstall functionality with clean restoration
# - Dry-run mode for testing and validation
# - Verbose logging and error handling
#
# INSTALLATION PROCESS:
# 1. Environment detection (OS, shell, package manager)
# 2. Dependency checking and installation
# 3. Repository cloning/updating
# 4. Configuration file installation (neofetch, fastfetch)
# 5. Package installation (eza, htop, etc.)
# 6. Shell configuration and alias sourcing
# 7. Autocompletion setup
#
# USAGE:
#   ./install.sh [options]
#
# COMMAND LINE OPTIONS:
#   --help              Show comprehensive help message
#   --dry-run           Preview installation without making changes
#   --force             Force reinstallation, overwriting existing configurations
#   --uninstall         Complete removal with backup restoration
#   --minimal           Minimal installation (aliases + config + scripts only)
#   --no-packages       Skip system package installation
#   --verbose           Enable detailed logging and debug information
#   --shell SHELL       Override automatic shell detection
#
# CONFIGURATION FILES INSTALLED:
#   - ~/.config/neofetch/config.conf      (Neofetch display configuration)
#   - ~/.config/fastfetch/config.jsonc    (Fastfetch display configuration)
#   - ~/.bashrc/.zshrc/etc.               (Shell configuration with aliases)
#
# SUPPORTED SYSTEMS:
#   - Ubuntu, Debian, Linux Mint          (apt)
#   - Fedora, RHEL, CentOS                (dnf)
#   - Arch Linux, Manjaro                 (pacman)
#   - Alpine Linux                        (apk)
#   - openSUSE                            (zypper)
#   - Gentoo                              (emerge)
#
# TROUBLESHOOTING:
# - If installation fails, check that git and curl are installed
# - Ensure you have sudo privileges for package installation
# - Use --verbose flag for detailed error information
# - Check ~/.alias-hub-backup-* files for configuration restoration
#
# For more information, visit: https://github.com/1999AZZAR/alias-hub
#
# ==============================================================================

set -euo pipefail

# --- Configuration ---
readonly REPO_URL="https://github.com/1999AZZAR/alias-hub.git"
readonly ALIASES_DIR="$HOME/alias-hub"
readonly NEOFETCH_ASCII_INSTALLER_URL="https://raw.githubusercontent.com/1999AZZAR/neofetch_ascii/master/install.sh"
readonly SCRIPT_VERSION="2.1.0"

# Generate backup suffix
BACKUP_SUFFIX=".alias-hub-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_SUFFIX

# --- Global Variables ---
DRY_RUN=false
FORCE=false
UNINSTALL=false
SKIP_PACKAGES=false
VERBOSE=false
PACKAGE_MANAGER=""
CURRENT_SHELL=""
SHELL_RC=""

# --- Color Codes for Output ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Helper Functions ---
print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    exit 1
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}DEBUG:${NC} $1"
    fi
}

command_exists() {
    command -v "$1" &> /dev/null
}

validate_environment() {
    print_verbose "Validating installation environment..."

    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_warning "This script is designed for Linux systems. Your OS: $OSTYPE"
        print_warning "Some features may not work correctly on non-Linux systems."
    fi

    # Check for internet connectivity
    if ! curl -s --connect-timeout 5 google.com >/dev/null 2>&1; then
        print_warning "No internet connection detected. Package installation may fail."
        print_warning "You can still install with --no-packages flag."
    fi

    # Check available disk space (minimum 50MB)
    local available_space
    available_space=$(df "$HOME" | tail -1 | awk '{print int($4/1024)}') # MB
    if [[ $available_space -lt 50 ]]; then
        print_warning "Low disk space detected: ${available_space}MB available"
        print_warning "At least 50MB free space recommended for installation."
    fi

    print_verbose "Environment validation completed"
}

validate_config_files() {
    print_verbose "Validating configuration files..."

    local missing_configs=0

    # Check if config files exist in repository
    declare -A required_configs=(
        ["$ALIASES_DIR/config/neofetch/config.conf"]="Neofetch configuration"
        ["$ALIASES_DIR/config/fastfetch/config.jsonc"]="Fastfetch configuration"
    )

    for config_file in "${!required_configs[@]}"; do
        if [[ ! -f "$config_file" ]]; then
            print_warning "Required config file missing: ${required_configs[$config_file]}"
            print_warning "File: $config_file"
            ((missing_configs+=1))
        else
            print_verbose "Found: ${required_configs[$config_file]}"
        fi
    done

    if [[ $missing_configs -gt 0 ]]; then
        print_warning "Found $missing_configs missing configuration files"
        print_warning "Installation may not work correctly without all config files."
    else
        print_verbose "All required configuration files are present"
    fi
}

package_installed() {
    local package="$1"
    case "$PACKAGE_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|zypper)
            rpm -q "$package" &>/dev/null
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        apk)
            apk info -e "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

detect_package_manager() {
    print_verbose "Detecting package manager..."

    if command_exists apt; then
        PACKAGE_MANAGER="apt"
        print_verbose "Detected apt package manager"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
        print_verbose "Detected dnf package manager"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        print_verbose "Detected pacman package manager"
    elif command_exists apk; then
        PACKAGE_MANAGER="apk"
        print_verbose "Detected apk package manager"
    elif command_exists zypper; then
        PACKAGE_MANAGER="zypper"
        print_verbose "Detected zypper package manager"
    elif command_exists emerge; then
        PACKAGE_MANAGER="emerge"
        print_verbose "Detected emerge package manager"
    else
        print_warning "No supported package manager found. Package installation will be skipped."
        PACKAGE_MANAGER=""
    fi
}

detect_shell() {
    print_verbose "Detecting shell..."

    # Get the current shell, fallback to $SHELL if needed
    CURRENT_SHELL="${CURRENT_SHELL:-$SHELL}"
    CURRENT_SHELL="${CURRENT_SHELL:-$(ps -p $$ -o cmd= | awk '{print $1}')}"

    # Extract basename
    CURRENT_SHELL="${CURRENT_SHELL##*/}"

    print_verbose "Detected shell: $CURRENT_SHELL"

    case "$CURRENT_SHELL" in
        bash)
            SHELL_RC="$HOME/.bashrc"
            ;;
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        ash|dash)
            SHELL_RC="$HOME/.profile"
            ;;
        *)
            print_warning "Unsupported shell: $CURRENT_SHELL. Supported shells: bash, zsh, fish, ash, dash"
            SHELL_RC=""
            ;;
    esac

    print_verbose "Shell RC file: $SHELL_RC"
}

create_backup() {
    local file="$1"
    if [[ -f "$file" && ! -L "$file" ]]; then
        local backup_file="${file}${BACKUP_SUFFIX}"
        print_verbose "Creating backup: $file -> $backup_file"
        if [[ "$DRY_RUN" == false ]]; then
            cp "$file" "$backup_file" || print_warning "Failed to backup $file"
        fi
        print_info "Backed up $file to $backup_file"
    fi
}

restore_backup() {
    local file="$1"
    local backup_file="${file}${BACKUP_SUFFIX}"
    if [[ -f "$backup_file" ]]; then
        print_verbose "Restoring backup: $backup_file -> $file"
        if [[ "$DRY_RUN" == false ]]; then
            mv "$backup_file" "$file"
        fi
        print_info "Restored $file from backup"
    fi
}

install_packages() {
    if [[ "$SKIP_PACKAGES" == true || -z "$PACKAGE_MANAGER" ]]; then
        print_info "Skipping package installation"
        return 0
    fi

    print_info "Installing required packages using $PACKAGE_MANAGER..."

    # Define packages for each package manager
    local packages=""
    case "$PACKAGE_MANAGER" in
        apt)
            packages="at eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip-full curl nmap lsof python3-pip python3-venv snapd flatpak fastfetch"
            ;;
        dnf)
            packages="at eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip curl nmap lsof python3-pip snapd flatpak fastfetch"
            ;;
        pacman)
            packages="at eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip curl nmap lsof python-pip snapd flatpak fastfetch"
            ;;
        apk)
            packages="at eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip curl nmap lsof py3-pip snapd flatpak fastfetch"
            ;;
        zypper)
            packages="at eza htop net-tools glances sysstat neofetch inxi ncdu tree zip unzip p7zip-full curl nmap lsof python3-pip snapd flatpak fastfetch"
            ;;
        *)
            print_warning "Unsupported package manager for installation"
            return 1
            ;;
    esac

    # Check which packages are not installed
    local packages_to_install=""
    for package in $packages; do
        if ! package_installed "$package"; then
            packages_to_install="$packages_to_install $package"
        else
            print_verbose "Package $package is already installed"
        fi
    done

    if [[ -z "$packages_to_install" ]]; then
        print_info "All required packages are already installed"
        return 0
    fi

    print_info "Installing packages:$packages_to_install"

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    local install_success=true

    case "$PACKAGE_MANAGER" in
        apt)
            if ! sudo apt update && sudo apt install -y "$packages_to_install"; then
                install_success=false
            fi
            ;;
        dnf)
            if ! sudo dnf install -y "$packages_to_install"; then
                install_success=false
            fi
            ;;
        pacman)
            if ! sudo pacman -S --noconfirm "$packages_to_install"; then
                install_success=false
            fi
            ;;
        apk)
            if ! sudo apk add "$packages_to_install"; then
                install_success=false
            fi
            ;;
        zypper)
            if ! sudo zypper install -y "$packages_to_install"; then
                install_success=false
            fi
            ;;
    esac

    if [[ "$install_success" == true ]]; then
        print_success "Package installation completed successfully"
    else
        print_warning "Some packages may not have installed correctly"
        print_warning "You can try installing them manually or run the installer again"
    fi
}

setup_configs() {
    print_info "Setting up configuration files..."

    # Define all config files to install
    declare -A config_files=(
        ["$ALIASES_DIR/config/neofetch/config.conf"]="$HOME/.config/neofetch/config.conf"
        ["$ALIASES_DIR/config/fastfetch/config.jsonc"]="$HOME/.config/fastfetch/config.jsonc"
    )

    local installed_configs=0
    local failed_configs=0

    for source_config in "${!config_files[@]}"; do
        local dest_config="${config_files[$source_config]}"
        local config_name=$(basename "$source_config")
        config_name="${config_name%.*}"
        local config_tool=$(basename "$(dirname "$dest_config")")

        print_verbose "Processing $config_tool $config_name config..."

        # Create config directory
        local config_dir=$(dirname "$dest_config")
        if [[ "$DRY_RUN" == false ]]; then
            if ! mkdir -p "$config_dir"; then
                print_warning "Failed to create directory: $config_dir"
                ((failed_configs+=1))
                continue
            fi
        else
            print_info "Would create directory: $config_dir"
        fi

        # Check if source config exists
        if [[ ! -f "$source_config" ]]; then
            print_warning "Source config not found: $source_config"
            ((failed_configs+=1))
            continue
        fi

        # Backup existing config if it exists and is not a symlink
        if [[ -f "$dest_config" && ! -L "$dest_config" ]]; then
            create_backup "$dest_config"
            if [[ "$DRY_RUN" == false ]]; then
                rm "$dest_config" || {
                    print_warning "Failed to remove existing config: $dest_config"
                    ((failed_configs+=1))
                    continue
                }
            fi
        fi

        # Copy new config
        if [[ "$DRY_RUN" == false ]]; then
            if cp "$source_config" "$dest_config"; then
                print_verbose "$config_tool config installed to $dest_config"
                ((installed_configs+=1))
            else
                print_warning "Failed to install $config_tool config to $dest_config"
                ((failed_configs+=1))
                continue
            fi
        else
            print_info "Would install $config_tool config to $dest_config"
            ((installed_configs+=1))
        fi

        # Special handling for neofetch ASCII art
        if [[ "$config_tool" == "neofetch" && "$config_name" == "config" ]]; then
            if command_exists neofetch && command_exists git; then
                print_info "Setting up Neofetch ASCII art..."
                if [[ "$DRY_RUN" == false ]]; then
                    if ! curl -sSL "$NEOFETCH_ASCII_INSTALLER_URL" | bash; then
                        print_warning "Neofetch ASCII installer failed. Neofetch might not display ASCII art correctly."
                    fi
                else
                    print_info "Would run Neofetch ASCII installer"
                fi
            else
                print_verbose "Skipping Neofetch ASCII art setup (dependencies missing)"
            fi
        fi
    done

    if [[ $installed_configs -gt 0 ]]; then
        print_success "Installed $installed_configs configuration files"
    fi

    if [[ $failed_configs -gt 0 ]]; then
        print_warning "Failed to install $failed_configs configuration files"
    fi
}

setup_aliases() {
    print_info "Configuring shell aliases..."

    if [[ -z "$SHELL_RC" ]]; then
        print_error "No supported shell configuration file found"
    fi

    # Create backup of shell RC file
    create_backup "$SHELL_RC"

    # Check if Alias Hub is already configured
    if grep -q "Alias Hub Configuration" "$SHELL_RC" 2>/dev/null; then
        if [[ "$FORCE" == false ]]; then
            print_info "Alias Hub is already configured in $SHELL_RC"
            return 0
        else
            print_info "Removing existing Alias Hub configuration for reinstall..."
            # Remove existing configuration block
            if [[ "$DRY_RUN" == false ]]; then
                sed -i '/# --- Alias Hub Configuration ---/,/# --- End Alias Hub Configuration ---/d' "$SHELL_RC"
            fi
        fi
    fi

    # Add Alias Hub configuration
    local config_block="
# --- Alias Hub Configuration ---
export ALIASES_DIR=\"$ALIASES_DIR\"
source \"\$ALIASES_DIR/script/helpers.sh\"
for file in \"\$ALIASES_DIR\"/*.alias; do source \"\$file\"; done

# Auto-completion for alias-list command (only for .alias files)
_alias_list_completions() {
    local current_word
    current_word=\"\${COMP_WORDS[COMP_CWORD]}\"
    local alias_files_no_ext
    alias_files_no_ext=\$(find \"\$ALIASES_DIR\" -maxdepth 1 -type f -name '*.alias' -exec basename {} .alias \\\;)
    COMPREPLY=(\$(compgen -W \"\$alias_files_no_ext\" -- \"\$current_word\"))
}
complete -F _alias_list_completions alias-list
# --- End Alias Hub Configuration ---
"

    if [[ "$DRY_RUN" == false ]]; then
        echo "$config_block" >> "$SHELL_RC"
    fi

    print_success "Alias Hub configured in $SHELL_RC"
}

uninstall() {
    print_info "Uninstalling Alias Hub..."

    # Remove aliases from shell RC
    if [[ -f "$SHELL_RC" ]] && grep -q "Alias Hub Configuration" "$SHELL_RC"; then
        print_info "Removing Alias Hub configuration from $SHELL_RC"
        if [[ "$DRY_RUN" == false ]]; then
            sed -i '/# --- Alias Hub Configuration ---/,/# --- End Alias Hub Configuration ---/d' "$SHELL_RC"
        fi
        print_success "Removed Alias Hub configuration from shell"
    fi

    # Restore config file backups
    print_info "Restoring original configurations..."
    restore_backup "$HOME/.config/neofetch/config.conf"
    restore_backup "$HOME/.config/fastfetch/config.jsonc"

    # Remove repository directory
    if [[ -d "$ALIASES_DIR" ]]; then
        print_info "Removing Alias Hub directory: $ALIASES_DIR"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$ALIASES_DIR"
        fi
        print_success "Removed Alias Hub directory"
    fi

    print_success "Alias Hub uninstallation completed"
    print_info "Please restart your shell or run 'source $SHELL_RC' to apply changes"
}

show_help() {
    cat << EOF
Alias Hub Installation Script v$SCRIPT_VERSION

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help              Show this help message
    --dry-run           Show what would be done without making changes
    --force             Force reinstallation, overwriting existing configs
    --uninstall         Remove Alias Hub and restore original configurations
    --minimal           Minimal installation (aliases + config + scripts only)
    --no-packages       Skip package installation
    --verbose           Enable verbose output
    --shell SHELL       Override shell detection (bash, zsh, fish, ash, dash)

EXAMPLES:
    $0                    # Normal installation
    $0 --dry-run          # Preview installation
    $0 --force            # Force reinstall
    $0 --uninstall        # Remove Alias Hub
    $0 --minimal          # Minimal installation
    $0 --no-packages      # Install without packages

For more information, visit: https://github.com/1999AZZAR/alias-hub
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                VERBOSE=true
                ;;
            --force)
                FORCE=true
                ;;
            --uninstall)
                UNINSTALL=true
                ;;
            --minimal)
                SKIP_PACKAGES=true
                ;;
            --no-packages)
                SKIP_PACKAGES=true
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --shell)
                CURRENT_SHELL="$2"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# --- Main Script ---

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Show banner
    echo "========================================"
    echo "  Alias Hub Installation Script v$SCRIPT_VERSION"
    echo "========================================"
    echo

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN MODE - No changes will be made"
        echo
    fi

    # Handle uninstall mode
    if [[ "$UNINSTALL" == true ]]; then
        detect_shell
        uninstall
        exit 0
    fi

    # Validate environment and requirements
    validate_environment

    # Detect environment
    detect_package_manager
    detect_shell

    # Validate configuration files
    validate_config_files

    # Check for required dependencies
    print_info "Checking for required tools (git, curl)..."
    for cmd in git curl; do
        if ! command_exists "$cmd"; then
            print_error "$cmd is not installed. Please install it first and try again."
        fi
    done

    # Clone or update repository
    if [[ -d "$ALIASES_DIR/.git" ]]; then
        print_info "Alias Hub directory already exists. Updating..."
        if [[ "$DRY_RUN" == false ]]; then
            (cd "$ALIASES_DIR" && git pull --quiet) || print_warning "Failed to update repository. Continuing with existing version."
        fi
    else
        print_info "Cloning Alias Hub repository..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth 1 --quiet "$REPO_URL" "$ALIASES_DIR" || print_error "Failed to clone repository."
        fi
    fi

    # Make scripts executable
    print_info "Setting up executable permissions..."
    if [[ "$DRY_RUN" == false ]]; then
        chmod +x "$ALIASES_DIR/script/helpers.sh"
        chmod +x "$ALIASES_DIR/script/system_cleaner.sh"
        chmod +x "$ALIASES_DIR/script/update_system.sh"
    fi

    # Setup configuration files
    setup_configs

    # Install packages
    install_packages

    # Configure aliases
    setup_aliases

    # Installation complete
    echo
    print_success "🎉 Alias Hub installation completed successfully!"
    echo
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "                           INSTALLATION SUMMARY"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo
    print_info "📁 Repository Location: $ALIASES_DIR"
    print_info "⚙️  Shell Configuration: $SHELL_RC"
    print_info "📋 Available Alias Files: $(ls -1 "$ALIASES_DIR"/*.alias | wc -l) categories"
    echo
    echo "───────────────────────────────────────────────────────────────────────"
    echo "                      🚀 GETTING STARTED"
    echo "───────────────────────────────────────────────────────────────────────"
    echo
    print_info "To apply changes immediately, run:"
    echo "  source $SHELL_RC"
    echo
    print_info "Or restart your shell/terminal."
    echo
    echo "───────────────────────────────────────────────────────────────────────"
    echo "                      🛠️  ESSENTIAL COMMANDS"
    echo "───────────────────────────────────────────────────────────────────────"
    echo
    print_info "📋 List all alias categories:"
    echo "  alias-list"
    echo
    print_info "🔍 Show aliases in a specific category:"
    echo "  alias-list system    # System management aliases"
    echo "  alias-list dev       # Development aliases"
    echo "  alias-list network   # Network aliases"
    echo
    print_info "💻 System information:"
    echo "  neofetch            # Beautiful system info"
    echo "  fastfetch           # Fast alternative system info"
    echo "  htop               # Interactive process viewer"
    echo "  glances            # System monitoring dashboard"
    echo
    echo "───────────────────────────────────────────────────────────────────────"
    echo "                      📚 LEARN MORE"
    echo "───────────────────────────────────────────────────────────────────────"
    echo
    print_info "📖 Full documentation: https://github.com/1999AZZAR/alias-hub"
    print_info "🆘 Troubleshooting: Check the README.md file"
    print_info "🔧 Advanced usage: Explore the script/ directory"
    echo
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "                     ✨ HAPPY TERMINALING! ✨"
    echo "═══════════════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"
