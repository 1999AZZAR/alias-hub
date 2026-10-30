# ==============================================================================
# PACKAGE MANAGER WRAPPERS
# ==============================================================================
# Wrapper functions for package managers (apt, snap, flatpak, nix) that
# automatically handle sudo elevation when needed.
#
# MODULE: package_managers.sh
# LOCATION: script/sub_scripts/package_managers.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - apt() - Wrapper for apt with automatic sudo
# - snap() - Wrapper for snap with automatic sudo
# - flatpak() - Wrapper for flatpak with conditional sudo
# - nix() - Wrapper for nix (always per-user; never elevated)
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

# --- Wrapper for 'nix' (single-user profile, never elevated) ---
# Auto-source Nix daemon environment if present on non-NixOS but not yet in PATH
if ! command -v nix &>/dev/null; then
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi

# Nix profiles are per-user; running it under sudo would corrupt ownership of
# the profile and the daemon connection, so this wrapper never elevates.
# Unqualified package arguments are resolved against nixpkgs automatically,
# e.g. `nix profile install fzf` installs nixpkgs#fzf.
nix() {
  if ! command -v nix &>/dev/null; then
    echo "Error: nix command not found. Install the Nix package manager first." >&2
    return 1
  fi
  if [[ "$1" == "profile" && "$2" =~ ^(install|remove|rename|rollback|upgrade)$ ]]; then
    shift # profile
    local subcommand="$1"
    shift
    local args=()
    for arg in "$@"; do
      if [[ "$subcommand" == install && "$arg" != *'#'* ]]; then
        args+=("nixpkgs#$arg")
      else
        args+=("$arg")
      fi
    done
    command nix profile "$subcommand" "${args[@]}"
    return
  fi
  command nix "$@"
}

