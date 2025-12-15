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

  # Execute the advanced update script.
  # The script itself handles sudo elevation, so we don't need it here.
  echo "--- Launching the Smart System Update Script ---"
  "$UPDATE_SCRIPT_PATH"
  echo "--- Script finished. ---"
}

# --- System Cleanup Alias ---
# This function calls the external clean_system.sh script.
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

  # Execute the script with a 15-minute (900s) timeout.
  echo "--- Launching the System Cleanup Script ---"
  "$CLEAN_SCRIPT_PATH"
  echo "--- Script finished. ---"
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

