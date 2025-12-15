# ==============================================================================
# POWER MANAGEMENT (TLP)
# ==============================================================================
# A wrapper function to manage TLP (Linux Advanced Power Management).
#
# MODULE: power_management.sh
# LOCATION: script/sub_scripts/power_management.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - tlp() - Manage TLP power management service
#
# USAGE:
#   tlp on              - Turn TLP on and enable it
#   tlp off             - Turn TLP off and disable it
#   tlp off <minutes>   - Turn TLP off for a specified number of minutes
#   tlp status          - Check the current status of TLP
#   tlp help            - Show help message
#
# DEPENDENCIES:
# - systemctl - For service management
# - at - For scheduling (required for timed off feature)
#
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

