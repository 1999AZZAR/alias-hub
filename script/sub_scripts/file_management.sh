# ==============================================================================
# FILE MANAGEMENT TOOLS
# ==============================================================================
# Enhanced file and directory management functions.
#
# MODULE: file_management.sh
# LOCATION: script/sub_scripts/file_management.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - cd() - Enhanced cd with automatic directory listing using eza or ls
# - mkcd() - Create directory and change into it
# - findc() - Find files by content using grep
# - rename_ext() - Batch rename file extensions
#
# DEPENDENCIES:
# - eza (optional) - For enhanced directory listing
# - find, grep - Standard Unix tools
#
# ==============================================================================

# --- Enhanced cd with eza ---
cd() {
  if [ -n "$1" ]; then
    builtin cd "$@" || return $?
  else
    builtin cd ~ || return $?
  fi
  if command -v eza &>/dev/null; then
    eza --icons --group-directories-first
  else
    echo "Warning: eza not found, falling back to ls." >&2
    ls --color=auto --group-directories-first
  fi
}

# --- mkdir and cd helper ---
mkcd() {
  if ! command -v mkdir &>/dev/null; then
    echo "Error: mkdir command not found." >&2
    return 1
  fi
  mkdir -pv "$1" && cd "$1"
}

# --- Find files by content ---
findc() {
  if ! command -v find &>/dev/null; then
    echo "Error: find command not found." >&2
    return 1
  fi
  if ! command -v grep &>/dev/null; then
    echo "Error: grep command not found." >&2
    return 1
  fi
  find . -type f -exec grep -l "$1" {} \;
}

# --- Batch rename files ---
rename_ext() {
  if [ $# -ne 2 ]; then
    echo "Usage: rename-ext old_extension new_extension" >&2
    return 1
  fi
  if ! command -v find &>/dev/null; then
    echo "Error: find command not found." >&2
    return 1
  fi
  find . -name "*.$1" -exec bash -c 'mv "$0" "${0%.$1}.$2"' {} "$1" "$2" \;
}

