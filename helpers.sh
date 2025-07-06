# helpers.sh: centralized functions for alias-hub (sourced, no shebang)

# Remove alias eval to avoid overriding built-in eval
unalias eval 2>/dev/null

apt() {
  if ! command -v apt &> /dev/null; then
    echo "Error: apt command not found. Please install apt." >&2
    return 1
  fi
  sudo /usr/bin/apt "$@"
}

snap() {
  if ! command -v snap &> /dev/null; then
    echo "Error: snap command not found. Please install snapd." >&2
    return 1
  fi
  sudo /usr/bin/snap "$@"
}

flatpak() {
  if ! command -v flatpak &> /dev/null; then
    echo "Error: flatpak command not found. Please install flatpak." >&2
    return 1
  fi
  case "$1" in
  install | update | remove | override | repair | uninstall)
    sudo /usr/bin/flatpak "$@"
    ;;
  *)
    /usr/bin/flatpak "$@"
    ;;
  esac
}

# Kubernetes shortcut alias
alias k='kubectl'

# IDF wrapper (for ESP-IDF commands)
idf() {
  if ! command -v idf.py &> /dev/null; then
    echo "Error: idf.py command not found. Please ensure ESP-IDF is installed and configured." >&2
    return 1
  fi
  idf.py "$@"
}

# ESPTool wrapper (for ESP32 tools)
esptool() {
  if ! command -v esptool.py &> /dev/null; then
    echo "Error: esptool.py command not found. Please ensure ESPTool is installed." >&2
    return 1
  fi
  esptool.py "$@"
}

# System update
update() {
  apt update && apt upgrade -y && apt autoremove -y
  if command -v snap &> /dev/null; then
    snap refresh
  else
    echo "Warning: snap not found, skipping snap refresh." >&2
  fi
  if command -v flatpak &> /dev/null; then
    flatpak update -y
  else
    echo "Warning: flatpak not found, skipping flatpak update." >&2
  fi
}

# Dist upgrade including OS release upgrade
dis_update() {
  apt update && apt upgrade -y && apt dist-upgrade -y
  if command -v do-release-upgrade &> /dev/null; then
    sudo do-release-upgrade
  else
    echo "Error: do-release-upgrade command not found. Cannot perform distribution upgrade." >&2
    return 1
  fi
}

# Plymouth boot splash
boot_splash() {
  if ! command -v plymouthd &> /dev/null || ! command -v plymouth &> /dev/null; then
    echo "Error: plymouthd or plymouth command not found. Cannot run boot splash." >&2
    return 1
  fi
  sudo plymouthd
  sudo plymouth --show-splash
  for ((i = 0; i < 5; i++)); do
    sleep 1
    sudo plymouth --update=test$i
  done
  sudo plymouth --quit
}

# ASCII art wrapper: use looper.sh for options, else figlet if available
ascii() {
  local loopers_script="${ALIASES_DIR}/ascii-scripts/loopers.sh"

  # If no arguments, try to run loopers.sh with -r (random)
  if [ $# -eq 0 ]; then
    if [ -f "$loopers_script" ] && [ -x "$loopers_script" ]; then
      bash "$loopers_script" -r
      return
    fi
  fi

  # If first arg is an option, pass through to loopers.sh if available
  if [[ "$1" == -* ]]; then
    if [ -f "$loopers_script" ] && [ -x "$loopers_script" ]; then
      bash "$loopers_script" "$@"
      return
    fi
  fi

  # For text input, use figlet if available
  if command -v figlet &> /dev/null; then
    echo "$*" | figlet
    return
  fi

  # Fallback to loopers.sh if it exists and is executable
  if [ -f "$loopers_script" ] && [ -x "$loopers_script" ]; then
    bash "$loopers_script" "$@"
    return
  fi

  echo "Error: No ASCII art engine found. Please install 'figlet' or ensure 'loopers.sh' is in your ALIASES_DIR." >&2
  return 1
}

# Prevent pip recursion
pip() {
  if ! command -v pip &> /dev/null; then
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
        if command -v tar &> /dev/null; then tar xvjf "$archive"; else echo "Error: tar command not found." >&2; fi ;;
      *.tar.gz | *.tgz) 
        if command -v tar &> /dev/null; then tar xvzf "$archive"; else echo "Error: tar command not found." >&2; fi ;;
      *.bz2) 
        if command -v bunzip2 &> /dev/null; then bunzip2 "$archive"; else echo "Error: bunzip2 command not found." >&2; fi ;;
      *.rar) 
        if command -v unrar &> /dev/null; then unrar e -r "$archive"; else echo "Error: unrar command not found." >&2; fi ;;
      *.gz) 
        if command -v gunzip &> /dev/null; then gunzip "$archive"; else echo "Error: gunzip command not found." >&2; fi ;;
      *.tar) 
        if command -v tar &> /dev/null; then tar xvf "$archive"; else echo "Error: tar command not found." >&2; fi ;;
      *.zip) 
        if command -v unzip &> /dev/null; then unzip -q "$archive"; else echo "Error: unzip command not found." >&2; fi ;;
      *.Z) 
        if command -v uncompress &> /dev/null; then uncompress "$archive"; else echo "Error: uncompress command not found." >&2; fi ;;
      *.7z) 
        if command -v 7z &> /dev/null; then 7z x "$archive"; else echo "Error: 7z command not found." >&2; fi ;;
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
    if command -v tar &> /dev/null; then tar -czvf "$archive_name" "$@"; else echo "Error: tar command not found." >&2; return 1; fi ;;
  *.tar.bz2 | *.tbz) 
    if command -v tar &> /dev/null; then tar -cjvf "$archive_name" "$@"; else echo "Error: tar command not found." >&2; return 1; fi ;;
  *.tar) 
    if command -v tar &> /dev/null; then tar -cvf "$archive_name" "$@"; else echo "Error: tar command not found." >&2; return 1; fi ;;
  *.zip) 
    if command -v zip &> /dev/null; then zip -r "$archive_name" "$@"; else echo "Error: zip command not found." >&2; return 1; fi ;;
  *.7z) 
    if command -v 7z &> /dev/null; then 7z a "$archive_name" "$@"; else echo "Error: 7z command not found." >&2; return 1; fi ;;
  *.rar) 
    if command -v rar &> /dev/null; then rar a "$archive_name" "$@"; else echo "Error: rar command not found." >&2; return 1; fi ;;
  *) echo "Unsupported archive format: $archive_name" >&2; return 1; ;;
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
  if command -v exa &> /dev/null; then
    exa --icons --group-directories-first
  else
    echo "Warning: exa not found, falling back to ls." >&2
    ls --color=auto --group-directories-first
  fi
}

# Unified back: no arg = toggle, arg = levels
back() {
  if [ -z "$1" ]; then
    builtin cd - || return $?
  else
    local dirs="cd "
    for ((i = 0; i < $1; i++)); do dirs+="../"; done
    eval "$dirs" || return $?
  fi
  if command -v ls &> /dev/null; then
    ls --color=auto --group-directories-first
  else
    echo "Warning: ls command not found." >&2
    return 1
  fi
}

# mkdir and cd helper
mkcd() {
  if ! command -v mkdir &> /dev/null; then
    echo "Error: mkdir command not found." >&2
    return 1
  fi
  mkdir -pv "$1" && cd "$1"
}

# find files by content
findc() {
  if ! command -v find &> /dev/null; then
    echo "Error: find command not found." >&2
    return 1
  fi
  if ! command -v grep &> /dev/null; then
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
  if ! command -v find &> /dev/null; then
    echo "Error: find command not found." >&2
    return 1
  fi
  find . -name "*.$1" -exec bash -c 'mv "$1" "${1%.$2}.$3"' - {} "$1" "$2" \;
}

# Curl wrapper
cw() {
  if ! command -v curl &> /dev/null; then
    echo "Error: curl command not found." >&2
    return 1
  fi
  curl -s "$@"
}

# Weather and info
weather() { cw wttr.in/"${1:-}"; }
moon() { cw wttr.in/Moon; }
horo() {
  if ! command -v date &> /dev/null; then
    echo "Error: date command not found." >&2
    return 1
  fi
  cw "http://horoscope-api.herokuapp.com/horoscope/today/$(date +%A)"
}

# News feeds
hn() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq command not found. Please install jq." >&2
    return 1
  fi
  cw https://hn.algolia.com/api/v1/search?query=front_page | jq .
}
trending_coins() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq command not found. Please2 install jq." >&2
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
    if ! command -v jq &> /dev/null; then
      echo "Error: jq command not found. Please install jq." >&2
      return 1
    fi
    cw http://quotes.stormconsultancy.co.uk/random.json | jq -r .quote ;;
  joke) 
    if ! command -v jq &> /dev/null; then
      echo "Error: jq command not found. Please install jq." >&2
      return 1
    fi
    cw https://icanhazdadjoke.com/ | jq -r .joke ;;
  *) echo "Usage: fun {dice|coin|color|quote|joke}" ;;
  esac
}
