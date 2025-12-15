# ==============================================================================
# SYSTEM UTILITIES
# ==============================================================================
# Various system utility functions for testing and system management.
#
# MODULE: system_utilities.sh
# LOCATION: script/sub_scripts/system_utilities.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - boot_splash() - Test Plymouth boot splash screen
#
# ==============================================================================

# --- Plymouth boot splash test ---
boot_splash() {
  if ! command -v plymouthd &>/dev/null || ! command -v plymouth &>/dev/null; then
    echo "Error: plymouthd or plymouth command not found. Cannot run boot splash." >&2
    return 1
  fi

  # Check if plymouth is already running
  if pgrep plymouthd &>/dev/null; then
    echo "Notice: plymouthd is already running." >&2
    return 1
  fi

  echo "Starting plymouth boot splash test..."
  sudo plymouthd --mode=boot
  sleep 2  # Give plymouthd time to start
  sudo plymouth --show-splash

  for ((i = 0; i < 5; i++)); do
    sleep 1
    sudo plymouth --update="test$i"
  done

  sudo plymouth --quit
  echo "Plymouth boot splash test completed."
}

