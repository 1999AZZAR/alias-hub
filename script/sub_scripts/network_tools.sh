# ==============================================================================
# NETWORK TOOLS
# ==============================================================================
# Network utilities and web API integration functions.
#
# MODULE: network_tools.sh
# LOCATION: script/sub_scripts/network_tools.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - cw() - Curl wrapper for silent requests
# - weather() - Get weather information from wttr.in
# - moon() - Get moon phase information
# - horo() - Get daily horoscope
# - hn() - Get Hacker News front page
# - trending_coins() - Get trending cryptocurrency information
#
# DEPENDENCIES:
# - curl - For HTTP requests
# - jq (optional) - For JSON parsing in some functions
#
# ==============================================================================

# --- Curl wrapper ---
cw() {
  if ! command -v curl &>/dev/null; then
    echo "Error: curl command not found." >&2
    return 1
  fi
  curl -s "$@"
}

# --- Weather and info ---
weather() {
  cw wttr.in/"${1:-}"
}

moon() {
  cw wttr.in/Moon
}

horo() {
  if ! command -v date &>/dev/null; then
    echo "Error: date command not found." >&2
    return 1
  fi
  cw "http://horoscope-api.herokuapp.com/horoscope/today/$(date +%A)"
}

# --- News feeds ---
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

# --- Network speedtest with complete stats ---
# Calls the external network_speedtest.sh script (latency, loss,
# download/upload, DNS, IP/ISP info, interface counters).
netspeedtest() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

  local SPEED_SCRIPT_PATH="$SCRIPT_DIR/network_speedtest.sh"

  if [[ ! -f "$SPEED_SCRIPT_PATH" ]]; then
    echo "Error: The 'network_speedtest.sh' script was not found." >&2
    echo "Expected at: $SPEED_SCRIPT_PATH" >&2
    return 1
  fi

  if [[ ! -x "$SPEED_SCRIPT_PATH" ]]; then
    echo "Notice: Making the speedtest script executable for the first time."
    chmod +x "$SPEED_SCRIPT_PATH"
  fi

  echo "--- Launching the Network Speedtest Script ---"
  "$SPEED_SCRIPT_PATH" "$@"
  local status=$?

  if [[ $status -ne 0 ]]; then
    echo "Error: Speedtest script failed with exit status $status." >&2
  fi

  echo "--- Script finished. ---"
  return "$status"
}

