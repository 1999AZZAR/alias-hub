# helpers.sh: centralized functions for alias-hub (sourced, no shebang)

# apt wrapper (with sudo)
apt() { sudo apt "$@"; }

# snap wrapper (with sudo)
snap() { sudo snap "$@"; }

# docker wrapper
docker_cmd() { docker "$@"; }

# Docker wrapper: generic docker function
d() { docker "$@"; }

# flatpak wrapper
flatpak() { flatpak "$@"; }

# Kubernetes wrapper
k() { kubectl "$@"; }

# IDF wrapper (for ESP-IDF commands)
idf() { idf.py "$@"; }

# ESPTool wrapper (for ESP32 tools)
esptool() { esptool.py "$@"; }

# System update
update() { apt update && apt upgrade -y && apt autoremove -y && snap refresh && flatpak update -y; }

# Dist upgrade including OS release upgrade
dis_update() { apt update && apt upgrade -y && apt dist-upgrade -y && sudo do-release-upgrade; }

# Plymouth boot splash
boot_splash() { sudo plymouthd; sudo plymouth --show-splash; for ((i=0; i<5; i++)); do sleep 1; sudo plymouth --update=test$i; done; sudo plymouth --quit; }

# ASCII art wrapper: use figlet or fallback to local loopers
ascii() {
  local od="$(pwd)"
  if command -v figlet >/dev/null; then
    echo "$*" | figlet
  elif [ -f "${ALIASES_DIR}/looper.sh" ]; then
    cd "${ALIASES_DIR}" && bash looper.sh "$@" && cd "$od"
  else
    echo "Error: no ASCII art engine found (install figlet or add looper.sh to ${ALIASES_DIR})"
    return 1
  fi
}

# Prevent pip recursion
pip() { command pip "$@" --break-system-packages; }

# Extract archives
extract() {
  for archive in "$@"; do
    if [ -f "$archive" ]; then
      case $archive in
        *.tar.bz2) tar xvjf "$archive" ;;  *.tar.gz) tar xvzf "$archive" ;;  *.bz2) bunzip2 "$archive" ;;  *.rar) unrar e -r "$archive" ;;  *.gz) gunzip "$archive" ;;  *.tar) tar xvf "$archive" ;;  *.tbz2) tar xvjf "$archive" ;;  *.tgz) tar xvzf "$archive" ;;  *.zip) unzip -q "$archive" ;;  *.Z) uncompress "$archive" ;;  *.7z) 7z x "$archive" ;;  *) echo "Don't know how to extract '$archive'..." ;;
      esac
      echo "Extracted: $archive"
    else
      echo "'$archive' is not a valid file!"
    fi
  done
}

# Create archives
archive() {
  if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: archive [archive_name.ext] [file/dir1] [file/dir2] ..."; return 1; fi
  local archive_name="$1"; shift
  case "$archive_name" in
    *.tar.gz|*.tgz) tar -czvf "$archive_name" "$@" ;;  *.tar.bz2|*.tbz) tar -cjvf "$archive_name" "$@" ;;  *.tar) tar -cvf "$archive_name" "$@" ;;  *.zip) zip -r "$archive_name" "$@" ;;  *.7z) 7z a "$archive_name" "$@" ;;  *.rar) rar a "$archive_name" "$@" ;;  *) echo "Unsupported archive format: $archive_name" ;;
  esac
  [ $? -eq 0 ] && echo "Created archive: $archive_name"
}

# Enhanced cd with exa
cd() {
  if [ -n "$1" ]; then
    builtin cd "$@" && exa --icons --group-directories-first
  else
    builtin cd ~ && exa --icons --group-directories-first
  fi
}

# Unified back: no arg = toggle, arg = levels
back() {
  if [ -z "$1" ]; then
    builtin cd - && ls
  else
    local dirs="cd "; for ((i=0; i<$1; i++)); do dirs+="../"; done; eval "$dirs" && ls
  fi
}

# mkdir and cd helper
mkcd() { mkdir -pv "$1" && cd "$1"; }

# find files by content
findc() { find . -type f -exec grep -l "$1" {} \;; }

# batch rename files
rename_ext() {
  if [ $# -ne 2 ]; then echo "Usage: rename-ext old_extension new_extension"; return 1; fi
  find . -name "*.$1" -exec bash -c 'mv "$1" "${1%.$2}.$3"' - {} "$1" "$2" \;
}

# Auto-completion for alias-list command
_alias_list_completions() {
  local current_word="${COMP_WORDS[COMP_CWORD]}"
  local matches
  if [ -d "${ALIASES_DIR}" ]; then
    matches=$(compgen -W "$(find "${ALIASES_DIR}" -name "*.alias" -type f -printf "%f\n" | sed 's/\.alias$//')" -- "${current_word}")
    COMPREPLY=(${matches})
  fi
}

# Enable completion for alias-list
complete -F _alias_list_completions alias-list

# Curl wrapper
cw() { curl -s "$@"; }

# Weather and info
weather() { cw wttr.in/"${1:-}"; }
moon() { cw wttr.in/Moon; }
horo() { cw "http://horoscope-api.herokuapp.com/horoscope/today/$(date +%A)"; }

# News feeds
hn() { cw https://hn.algolia.com/api/v1/search?query=front_page | jq .; }
trending_coins() { cw https://api.coingecko.com/api/v3/search/trending | jq .; }

# Random fun generator
fun() {
  case "$1" in
    dice) echo $((RANDOM % 6 + 1)) ;;
    coin) echo $((RANDOM % 2 == 0 ? "Heads" : "Tails")) ;;
    color) echo "[38;5;$((RANDOM%256))m█[0m" ;;
    quote) cw http://quotes.stormconsultancy.co.uk/random.json | jq -r .quote ;;
    joke) cw https://icanhazdadjoke.com/ | jq -r .joke ;;
    *) echo "Usage: fun {dice|coin|color|quote|joke}" ;;
  esac
}
