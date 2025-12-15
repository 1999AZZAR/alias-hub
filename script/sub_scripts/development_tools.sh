# ==============================================================================
# DEVELOPMENT TOOLS
# ==============================================================================
# Wrapper functions and aliases for development tools and environments.
#
# MODULE: development_tools.sh
# LOCATION: script/sub_scripts/development_tools.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - k() - Kubernetes kubectl shortcut alias
# - idf() - ESP-IDF wrapper function
# - esptool() - ESPTool wrapper function for ESP32 tools
#
# ==============================================================================

# --- Kubernetes shortcut alias ---
alias k='kubectl'

# --- IDF wrapper (for ESP-IDF commands) ---
idf() {
  if ! command -v idf.py &>/dev/null; then
    echo "Error: idf.py command not found. Please ensure ESP-IDF is installed and configured." >&2
    return 1
  fi
  idf.py "$@"
}

# --- ESPTool wrapper (for ESP32 tools) ---
esptool() {
  if ! command -v esptool.py &>/dev/null; then
    echo "Error: esptool.py command not found. Please ensure ESPTool is installed." >&2
    return 1
  fi
  esptool.py "$@"
}

