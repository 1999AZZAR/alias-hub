# ==============================================================================
# ASCII ART GENERATOR
# ==============================================================================
# A wrapper function to generate ASCII art using loopers.sh or figlet.
#
# MODULE: ascii_art.sh
# LOCATION: script/sub_scripts/ascii_art.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - ascii() - Intelligently choose between loopers.sh and figlet for ASCII art
#
# DEPENDENCIES:
# - loopers.sh (optional) - For displaying pre-made ASCII art files
# - figlet (optional) - For converting text into ASCII art
#
# ==============================================================================

# --- ASCII Art Wrapper ---
# This function intelligently chooses between two tools:
# 1. A custom script 'loopers.sh' for displaying pre-made ASCII art files.
#    - Used when no arguments are given (shows a random one).
#    - Used when an option (like -r, -l, -c) is passed.
# 2. The standard 'figlet' utility for converting text into ASCII art.
#    - Used for any input that is not an option.
#
# It provides sensible fallbacks and clear error messages if tools are missing.
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

