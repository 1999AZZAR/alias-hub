# ==============================================================================
# ENTERTAINMENT FUNCTIONS
# ==============================================================================
# Random fun generators and entertainment utilities.
#
# MODULE: entertainment.sh
# LOCATION: script/sub_scripts/entertainment.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - fun() - Random fun generator with multiple options
#
# USAGE:
#   fun dice    - Roll a dice (1-6)
#   fun coin    - Flip a coin (Heads/Tails)
#   fun color   - Display a random color block
#   fun quote   - Get a random quote
#   fun joke    - Get a random dad joke
#
# DEPENDENCIES:
# - jq (optional) - For JSON parsing in quote and joke functions
# - curl (via cw) - For API requests
#
# ==============================================================================

# --- Random fun generator ---
fun() {
  case "$1" in
  dice)
    echo $((RANDOM % 6 + 1))
    ;;
  coin)
    echo $((RANDOM % 2 == 0 ? "Heads" : "Tails"))
    ;;
  color)
    echo "[38;5;$((RANDOM % 256))mâ–ˆ[0m"
    ;;
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
  *)
    echo "Usage: fun {dice|coin|color|quote|joke}"
    ;;
  esac
}

