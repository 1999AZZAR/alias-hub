# ==============================================================================
# PYTHON TOOLS
# ==============================================================================
# Wrapper functions for Python package management.
#
# MODULE: python_tools.sh
# LOCATION: script/sub_scripts/python_tools.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - pip() - Wrapper for pip with --break-system-packages flag
#
# ==============================================================================

# --- Prevent pip recursion and add system packages flag ---
pip() {
  if ! command -v pip &>/dev/null; then
    echo "Error: pip command not found. Please install pip." >&2
    return 1
  fi
  command pip "$@" --break-system-packages
}

