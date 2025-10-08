# ==============================================================================
# Shell Helper Functions
# centralized functions for alias-hub (sourced, no shebang)
#
# This file contains wrapper functions for common package managers
# and a master 'update' alias to run a comprehensive system update script.
#
# To use, source this file in your .bashrc or .zshrc:
#   source /path/to/your/helper.sh
# ==============================================================================

# Remove alias eval to avoid overriding built-in eval
unalias eval 2>/dev/null

# --- Wrapper for 'apt' to automatically use sudo ---
apt() {
  if ! command -v apt &>/dev/null; then
    echo "Error: apt command not found. Please install apt." >&2
    return 1
  fi
  # The actual apt binary is in /usr/bin/
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

# ==============================================================================
#                         --- System Update Alias ---
# This function now calls the external update_system.sh script for a more
# advanced and user-friendly update process.
# ==============================================================================
update() {
  # Determine the absolute path to the directory containing this script.
  # This makes the alias work regardless of the current working directory.
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

  # Define the full path to the target update script.
  local UPDATE_SCRIPT_PATH="$SCRIPT_DIR/update_system.sh"

  # Check if the update script actually exists.
  if [[ ! -f "$UPDATE_SCRIPT_PATH" ]]; then
    echo "Error: The 'update_system.sh' script was not found in the same directory as helper.sh." >&2
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

# ==============================================================================
#                         --- System Cleanup Alias ---
# This function calls the external clean_system.sh script with a timeout.
# ==============================================================================
clean() {
  # Determine the absolute path to the directory containing this script.
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

  local CLEAN_SCRIPT_PATH="$SCRIPT_DIR/system_cleaner.sh"

  if [[ ! -f "$CLEAN_SCRIPT_PATH" ]]; then
    echo "Error: The 'clean_system.sh' script was not found in the same directory as helper.sh." >&2
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

# Kubernetes shortcut alias
alias k='kubectl'

# IDF wrapper (for ESP-IDF commands)
idf() {
  if ! command -v idf.py &>/dev/null; then
    echo "Error: idf.py command not found. Please ensure ESP-IDF is installed and configured." >&2
    return 1
  fi
  idf.py "$@"
}

# ESPTool wrapper (for ESP32 tools)
esptool() {
  if ! command -v esptool.py &>/dev/null; then
    echo "Error: esptool.py command not found. Please ensure ESPTool is installed." >&2
    return 1
  fi
  esptool.py "$@"
}

# Dist upgrade including OS release upgrade
dis_update() {
  apt update && apt upgrade -y && apt dist-upgrade -y
  if command -v do-release-upgrade &>/dev/null; then
    sudo do-release-upgrade
  else
    echo "Error: do-release-upgrade command not found. Cannot perform distribution upgrade." >&2
    return 1
  fi
}

# Plymouth boot splash
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

# ==============================================================================
#                         --- Ascii Alias ---
# ==============================================================================
# A wrapper function to generate ASCII art.
#
# This function intelligently chooses between two tools:
# 1. A custom script 'loopers.sh' for displaying pre-made ASCII art files.
#    - Used when no arguments are given (shows a random one).
#    - Used when an option (like -r, -l, -c) is passed.
# 2. The standard 'figlet' utility for converting text into ASCII art.
#    - Used for any input that is not an option.
#
# It provides sensible fallbacks and clear error messages if tools are missing.
# ==============================================================================

ascii() {
    # --- Configuration ---
    # !! IMPORTANT: Adjust this path to your loopers.sh script location.
    # Using "$HOME" makes it portable for your user account.
    local loopers_script="$HOME/Pictures/ascii/loopers.sh"

    # --- Pre-computation ---
    # Check for the required tools once to simplify the logic below.
    local can_use_loopers=false
    if [[ -f "$loopers_script" && -x "$loopers_script" ]]; then
        can_use_loopers=true
    fi

    local can_use_figlet=false
    if command -v figlet &>/dev/null; then
        can_use_figlet=true
    fi

    # --- Main Logic ---

    # Case 1: No arguments provided. Default to a random entry from loopers.sh.
    if [[ $# -eq 0 ]]; then
        if [[ "$can_use_loopers" == true ]]; then
            bash "$loopers_script" -r
            return 0
        else
            echo "Usage: ascii <text>" >&2
            echo "Info: For random art, ensure 'loopers.sh' is configured correctly." >&2
            return 1
        fi
    fi

    # Case 2: Argument is an option (starts with '-'). This is intended for loopers.sh.
    if [[ "$1" == -* ]]; then
        if [[ "$can_use_loopers" == true ]]; then
            bash "$loopers_script" "$@"
            return 0
        else
            echo "Error: Options like '$1' require the 'loopers.sh' script, which was not found or is not executable." >&2
            return 1
        fi
    fi

    # Case 3: Argument is text. Prioritize figlet for text-to-art conversion.
    # Use "$@" to pass all arguments to figlet.
    if [[ "$can_use_figlet" == true ]]; then
        figlet "$@"
        return 0
    fi

    # --- Fallback & Error ---
    # If we are here, it means the input was text but figlet is not available.
    echo "Error: 'figlet' is not installed or not in your PATH." >&2
    echo "Please run 'sudo apt-get install figlet' (or equivalent) to enable text-to-art conversion." >&2
    return 1
}

# Prevent pip recursion
pip() {
  if ! command -v pip &>/dev/null; then
    echo "Error: pip command not found. Please install pip." >&2
    return 1
  fi
  command pip "$@" --break-system-packages
}

# Extract archives
extract() {
  for archive in "$@"; do
    if [ -f "$archive" ]; then
      case $archive in
      *.tar.bz2 | *.tbz2)
        if command -v tar &>/dev/null; then tar xvjf "$archive"; else echo "Error: tar command not found." >&2; fi
        ;;
      *.tar.gz | *.tgz)
        if command -v tar &>/dev/null; then tar xvzf "$archive"; else echo "Error: tar command not found." >&2; fi
        ;;
      *.bz2)
        if command -v bunzip2 &>/dev/null; then bunzip2 "$archive"; else echo "Error: bunzip2 command not found." >&2; fi
        ;;
      *.rar)
        if command -v unrar &>/dev/null; then unrar e -r "$archive"; else echo "Error: unrar command not found." >&2; fi
        ;;
      *.gz)
        if command -v gunzip &>/dev/null; then gunzip "$archive"; else echo "Error: gunzip command not found." >&2; fi
        ;;
      *.tar)
        if command -v tar &>/dev/null; then tar xvf "$archive"; else echo "Error: tar command not found." >&2; fi
        ;;
      *.zip)
        if command -v unzip &>/dev/null; then unzip -q "$archive"; else echo "Error: unzip command not found." >&2; fi
        ;;
      *.Z)
        if command -v uncompress &>/dev/null; then uncompress "$archive"; else echo "Error: uncompress command not found." >&2; fi
        ;;
      *.7z)
        if command -v 7z &>/dev/null; then 7z x "$archive"; else echo "Error: 7z command not found." >&2; fi
        ;;
      *) echo "Don't know how to extract '$archive'..." ;;
      esac
      echo "Extracted: $archive"
    else
      echo "'$archive' is not a valid file!" >&2
    fi
  done
}

# Create archives
archive() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: archive [archive_name.ext] [file/dir1] [file/dir2] ..." >&2
    return 1
  fi
  local archive_name="$1"
  shift
  case "$archive_name" in
  *.tar.gz | *.tgz)
    if command -v tar &>/dev/null; then tar -czvf "$archive_name" "$@"; else
      echo "Error: tar command not found." >&2
      return 1
    fi
    ;;
  *.tar.bz2 | *.tbz)
    if command -v tar &>/dev/null; then tar -cjvf "$archive_name" "$@"; else
      echo "Error: tar command not found." >&2
      return 1
    fi
    ;;
  *.tar)
    if command -v tar &>/dev/null; then tar -cvf "$archive_name" "$@"; else
      echo "Error: tar command not found." >&2
      return 1
    fi
    ;;
  *.zip)
    if command -v zip &>/dev/null; then zip -r "$archive_name" "$@"; else
      echo "Error: zip command not found." >&2
      return 1
    fi
    ;;
  *.7z)
    if command -v 7z &>/dev/null; then 7z a "$archive_name" "$@"; else
      echo "Error: 7z command not found." >&2
      return 1
    fi
    ;;
  *.rar)
    if command -v rar &>/dev/null; then rar a "$archive_name" "$@"; else
      echo "Error: rar command not found." >&2
      return 1
    fi
    ;;
  *)
    echo "Unsupported archive format: $archive_name" >&2
    return 1
    ;;
  esac
  [ $? -eq 0 ] && echo "Created archive: $archive_name"
}

# Enhanced cd with exa
cd() {
  if [ -n "$1" ]; then
    builtin cd "$@" || return $?
  else
    builtin cd ~ || return $?
  fi
  if command -v exa &>/dev/null; then
    exa --icons --group-directories-first
  else
    echo "Warning: exa not found, falling back to ls." >&2
    ls --color=auto --group-directories-first
  fi
}

# mkdir and cd helper
mkcd() {
  if ! command -v mkdir &>/dev/null; then
    echo "Error: mkdir command not found." >&2
    return 1
  fi
  mkdir -pv "$1" && cd "$1"
}

# find files by content
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

# batch rename files
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

# Curl wrapper
cw() {
  if ! command -v curl &>/dev/null; then
    echo "Error: curl command not found." >&2
    return 1
  fi
  curl -s "$@"
}

# Weather and info
weather() { cw wttr.in/"${1:-}"; }
moon() { cw wttr.in/Moon; }
horo() {
  if ! command -v date &>/dev/null; then
    echo "Error: date command not found." >&2
    return 1
  fi
  cw "http://horoscope-api.herokuapp.com/horoscope/today/$(date +%A)"
}

# News feeds
hn() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq command not found. Please install jq." >&2
    return 1
  fi
  cw https://hn.algolia.com/api/v1/search?query=front_page | jq .
}
trending_coins() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq command not found. Please install jq." >&2
    return 1
  fi
  cw https://api.coingecko.com/api/v3/search/trending | jq .
}

# Random fun generator
fun() {
  case "$1" in
  dice) echo $((RANDOM % 6 + 1)) ;;
  coin) echo $((RANDOM % 2 == 0 ? "Heads" : "Tails")) ;;
  color) echo "[38;5;$((RANDOM % 256))m█[0m" ;;
  quote)
    if ! command -v jq &>/dev/null; then
      echo "Error: jq command not found. Please install jq." >&2
      return 1
    fi
    cw http://quotes.stormconsultancy.co.uk/random.json | jq -r .quote
    ;;
  joke)
    if ! command -v jq &>/dev/null; then
      echo "Error: jq command not found. Please install jq." >&2
      return 1
    fi
    cw https://icanhazdadjoke.com/ | jq -r .joke
    ;;
  *) echo "Usage: fun {dice|coin|color|quote|joke}" ;;
  esac
}

# ==============================================================================
#                         --- TLP Manager ---
# ==============================================================================
# A wrapper function to manage TLP (Linux Advanced Power Management).
#
# This function allows you to:
# - Turn TLP on and enable it: `tlp on`
# - Turn TLP off and disable it: `tlp off`
# - Temporarily turn TLP off for a specified number of minutes: `tlp off <minutes>`
#
# It checks the current status to avoid redundant commands and uses `sudo`
# for system-level changes. The temporary off feature uses the `at` command
# to schedule TLP to start again automatically.
# ==============================================================================

tlp() {
    # --- Pre-checks ---
    # Ensure systemctl and at commands are available.
    if ! command -v systemctl &>/dev/null; then
        echo "Error: 'systemctl' command not found. This function is not compatible with your system." >&2
        return 1
    fi

    if ! command -v at &>/dev/null; then
        echo "Error: 'at' command not found. Please install it (e.g., 'sudo apt install at') to use the timed off feature." >&2
        return 1
    fi

    # --- Helper Functions (nested for encapsulation) ---

    # Check if TLP service is currently active.
    _tlp_is_active() {
        systemctl is-active --quiet tlp
    }

    # --- Main Logic ---

    case "$1" in
        on)
            if _tlp_is_active; then
                echo "TLP is already on."
            else
                echo "Turning TLP on..."
                sudo systemctl start tlp
                # We also enable it to ensure it starts on the next boot.
                sudo systemctl enable tlp
                echo "TLP has been enabled and started."
            fi
            ;;

        off)
            # The second argument determines if it's a timed 'off' or permanent.
            local duration="$2"

            if ! _tlp_is_active; then
                echo "TLP is already off."
                return 0
            fi

            # If a duration is provided (and is a number), turn off temporarily.
            if [[ -n "$duration" && "$duration" =~ ^[0-9]+$ ]]; then
                echo "Turning TLP off for $duration minutes..."
                sudo systemctl stop tlp
                # Schedule the 'start' command to run after the specified duration.
                # The 'at' command handles the scheduling in the background.
                echo "sudo systemctl start tlp" | at now + "$duration" minutes
                echo "TLP is scheduled to turn back on automatically in $duration minutes."
            else
                # Otherwise, turn it off permanently (until next 'on' command).
                echo "Turning TLP off..."
                sudo systemctl stop tlp
                # We also disable it to prevent it from starting on the next boot.
                sudo systemctl disable tlp
                echo "TLP has been disabled and stopped."
            fi
            ;;

        status)
            if _tlp_is_active; then
                echo "TLP is currently on (active)."
            else
                echo "TLP is currently off (inactive)."
            fi
            # Optionally, show more detailed status
            systemctl status tlp | grep -E 'Active:|Loaded:'
            ;;

        help)
            echo "Usage: tlp {on|off|off <minutes>|status|help}"
            echo "Commands:"
            echo "  on                - Turn TLP on and enable it."
            echo "  off               - Turn TLP off and disable it."
            echo "  off <minutes>     - Turn TLP off for a specified number of minutes."
            echo "  status            - Check the current status of TLP."
            echo "  help              - Show this help message."
            ;;

        *)
            # Show usage instructions for invalid commands.
            echo "Usage: tlp {on|off|off <minutes>|status|help}" >&2
            return 1
            ;;
    esac
}
