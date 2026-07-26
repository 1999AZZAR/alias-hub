# ==============================================================================
# SYSTEM UPDATE FUNCTIONS
# ==============================================================================
# Functions for managing system updates and upgrades.
#
# MODULE: system_updates.sh
# LOCATION: script/sub_scripts/system_updates.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - update() - Advanced system update using update_system.sh script
# - clean() - System cleanup using system_cleaner.sh script
# - dis_update() - Distribution upgrade including OS release upgrade
#
# ==============================================================================

# --- System Update Alias ---
# This function calls the external update_system.sh script for a more
# advanced and user-friendly update process.
update() {
  # Determine the absolute path to the script directory (parent of sub_scripts).
  # This makes the alias work regardless of the current working directory.
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

  # Define the full path to the target update script.
  local UPDATE_SCRIPT_PATH="$SCRIPT_DIR/update_system.sh"

  # Check if the update script actually exists.
  if [[ ! -f "$UPDATE_SCRIPT_PATH" ]]; then
    echo "Error: The 'update_system.sh' script was not found." >&2
    echo "Expected at: $UPDATE_SCRIPT_PATH" >&2
    return 1
  fi

  # Ensure the update script is executable.
  if [[ ! -x "$UPDATE_SCRIPT_PATH" ]]; then
    echo "Notice: Making the update script executable for the first time."
    chmod +x "$UPDATE_SCRIPT_PATH"
  fi

  # Forward options and preserve the updater's exit status. Individual updater
  # operations have their own timeouts, so valid long upgrades are not killed.
  echo "--- Launching the Smart System Update Script ---"
  "$UPDATE_SCRIPT_PATH" "$@"
  local status=$?

  if [[ $status -ne 0 ]]; then
    echo "Error: Update script failed with exit status $status." >&2
  fi

  echo "--- Script finished. ---"
  return "$status"
}

# --- System Cleanup Alias ---
# This function calls the external system_cleaner.sh script.
clean() {
  # Determine the absolute path to the script directory (parent of sub_scripts).
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

  local CLEAN_SCRIPT_PATH="$SCRIPT_DIR/system_cleaner.sh"

  if [[ ! -f "$CLEAN_SCRIPT_PATH" ]]; then
    echo "Error: The 'system_cleaner.sh' script was not found." >&2
    echo "Expected at: $CLEAN_SCRIPT_PATH" >&2
    return 1
  fi

  if [[ ! -x "$CLEAN_SCRIPT_PATH" ]]; then
    echo "Notice: Making the cleanup script executable."
    chmod +x "$CLEAN_SCRIPT_PATH"
  fi

  # Forward options and preserve the cleaner's exit status.
  echo "--- Launching the System Cleanup Script ---"
  timeout --foreground --kill-after=10s 900s "$CLEAN_SCRIPT_PATH" "$@"
  local status=$?

  if [[ $status -eq 124 || $status -eq 137 ]]; then
    echo "Error: Cleanup script timed out after 15 minutes." >&2
  elif [[ $status -ne 0 ]]; then
    echo "Error: Cleanup script failed with exit status $status." >&2
  fi

  echo "--- Script finished. ---"
  return "$status"
}

# --- Distribution upgrade including OS release upgrade ---
dis_update() {
  apt update && apt upgrade -y && apt dist-upgrade -y
  if command -v do-release-upgrade &>/dev/null; then
    sudo do-release-upgrade
  else
    echo "Error: do-release-upgrade command not found. Cannot perform distribution upgrade." >&2
    return 1
  fi
}
