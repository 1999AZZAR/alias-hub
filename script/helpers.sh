# ==============================================================================
# ALIAS HUB - SHELL HELPER FUNCTIONS
# ==============================================================================
#
# Comprehensive shell helper functions for the Alias Hub collection
# This file now serves as a modular loader that sources individual module files
# from the sub_scripts directory for better organization and maintainability.
#
# FILE INFORMATION:
# - Location: script/helpers.sh
# - Type: Shell script (sourced, no shebang required)
# - Compatibility: Bash, Zsh, and other POSIX-compliant shells
# - Architecture: Modular - loads functions from sub_scripts/ directory
#
# MODULE STRUCTURE:
# All helper functions are organized into logical modules located in:
#   script/sub_scripts/
#
# Available modules:
# - package_managers.sh    - Package manager wrappers (apt, snap, flatpak)
# - system_updates.sh      - System update and cleanup functions
# - development_tools.sh   - Development tool wrappers (kubectl, ESP-IDF, etc.)
# - system_utilities.sh    - System utility functions (boot splash, etc.)
# - ascii_art.sh           - ASCII art generation tools
# - python_tools.sh        - Python package management tools
# - archive_tools.sh       - Archive extraction and creation
# - file_management.sh     - Enhanced file and directory operations
# - network_tools.sh       - Network utilities and web API functions
# - entertainment.sh       - Random fun generators and entertainment
# - power_management.sh    - TLP power management wrapper
#
# USAGE:
# Source this file in your shell configuration:
#   Bash:  source /path/to/alias-hub/script/helpers.sh
#   Zsh:   source /path/to/alias-hub/script/helpers.sh
#   Fish:  source /path/to/alias-hub/script/helpers.sh
#
# Or let the installer handle it automatically.
#
# CUSTOMIZATION:
# To load only specific modules, you can source individual files directly:
#   source /path/to/alias-hub/script/sub_scripts/package_managers.sh
#   source /path/to/alias-hub/script/sub_scripts/archive_tools.sh
#
# AUTHOR: Alias Hub Community
# VERSION: 2.1.0 (Modular Architecture)
# LICENSE: MIT
#
# ==============================================================================

# Remove alias eval to avoid overriding built-in eval
unalias eval 2>/dev/null

# Determine the directory containing this script
_ALIAS_HUB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_ALIAS_HUB_SUB_SCRIPTS_DIR="$_ALIAS_HUB_SCRIPT_DIR/sub_scripts"

# Check if sub_scripts directory exists
if [[ ! -d "$_ALIAS_HUB_SUB_SCRIPTS_DIR" ]]; then
    echo "Error: sub_scripts directory not found at: $_ALIAS_HUB_SUB_SCRIPTS_DIR" >&2
    echo "Please ensure the Alias Hub installation is complete." >&2
    return 1 2>/dev/null || exit 1
fi

# ==============================================================================
# MODULE LOADING
# ==============================================================================
# Load all module files in dependency order.
# Note: Some modules depend on others (e.g., entertainment.sh uses cw from network_tools.sh)
# ==============================================================================

# Core system modules (no dependencies)
_source_module() {
    local module_file="$1"
    local module_path="$_ALIAS_HUB_SUB_SCRIPTS_DIR/$module_file"
    
    if [[ -f "$module_path" ]]; then
        # Source the module silently
        source "$module_path" 2>/dev/null || {
            echo "Warning: Failed to load module: $module_file" >&2
            return 1
        }
    else
        echo "Warning: Module file not found: $module_file" >&2
        return 1
    fi
}

# Load modules in dependency order
# 1. Package managers (foundation)
_source_module "package_managers.sh"

# 2. System utilities (independent)
_source_module "system_utilities.sh"

# 3. Python tools (independent)
_source_module "python_tools.sh"

# 4. Archive tools (independent)
_source_module "archive_tools.sh"

# 5. File management (independent)
_source_module "file_management.sh"

# 6. Network tools (needed by entertainment)
_source_module "network_tools.sh"

# 7. System updates (uses package managers)
_source_module "system_updates.sh"

# 8. Development tools (independent)
_source_module "development_tools.sh"

# 9. ASCII art (independent)
_source_module "ascii_art.sh"

# 10. Entertainment (uses network_tools.sh cw function)
_source_module "entertainment.sh"

# 11. Power management (independent)
_source_module "power_management.sh"

# Clean up internal variables
unset _ALIAS_HUB_SCRIPT_DIR _ALIAS_HUB_SUB_SCRIPTS_DIR
unset -f _source_module

# ==============================================================================
# END OF ALIAS HUB SHELL HELPER FUNCTIONS LOADER
# ==============================================================================
#
# All helper functions have been loaded from their respective modules.
# The modular architecture allows for:
# - Better code organization and maintainability
# - Selective loading of specific modules if needed
# - Easier testing and debugging of individual components
# - Improved collaboration and contribution workflow
#
# For more information, visit: https://github.com/1999AZZAR/alias-hub
#
# ==============================================================================
