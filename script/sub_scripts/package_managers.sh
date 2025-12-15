# ==============================================================================
# PACKAGE MANAGER WRAPPERS
# ==============================================================================
# Wrapper functions for package managers (apt, snap, flatpak) that automatically
# handle sudo elevation when needed.
#
# MODULE: package_managers.sh
# LOCATION: script/sub_scripts/package_managers.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - apt() - Wrapper for apt with automatic sudo
# - snap() - Wrapper for snap with automatic sudo
# - flatpak() - Wrapper for flatpak with conditional sudo
#
# ==============================================================================

# --- Wrapper for 'apt' to automatically use sudo ---
apt() {
  if ! command -v apt &>/dev/null; then
    echo "Error: apt command not found. Please install apt." >&2
    return 1
  fi
  sudo /usr/bin/apt "$@"
}

# --- Wrapper for 'snap' to automatically use sudo ---
snap() {
  if ! command -v snap &>/dev/null; then
    echo "Error: snap command not found. Please install snapd." >&2
    return 1
  fi
  sudo /usr/bin/snap "$@"
}

# --- Wrapper for 'flatpak' to use sudo for privileged commands ---
flatpak() {
  if ! command -v flatpak &>/dev/null; then
    echo "Error: flatpak command not found. Please install flatpak." >&2
    return 1
  fi
  # Use sudo only for commands that modify the system installation
  case "$1" in
  install | update | remove | override | repair | uninstall)
    sudo /usr/bin/flatpak "$@"
    ;;
  *)
    # For other commands (like list, info, run), run as the user
    /usr/bin/flatpak "$@"
    ;;
  esac
}

