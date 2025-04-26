#!/usr/bin/env bash
# helpers.sh: centralized functions for alias-hub

# apt wrapper (with sudo)
apt() { sudo apt "$@"; }

# snap wrapper (with sudo)
snap() { sudo snap "$@"; }

# docker wrapper
docker_cmd() { docker "$@"; }

# flatpak wrapper
flatpak() { flatpak "$@"; }

# System update
update() { apt update && apt upgrade -y && apt autoremove -y && snap refresh && flatpak update -y; }

# Dist upgrade including OS release upgrade
dis_update() { apt update && apt upgrade -y && apt dist-upgrade -y && sudo do-release-upgrade; }

# Plymouth boot splash
boot_splash() { sudo plymouthd; sudo plymouth --show-splash; for ((i=0; i<5; i++)); do sleep 1; sudo plymouth --update=test$i; done; sudo plymouth --quit; }

# ASCII art wrapper
ascii() { original_dir=$(pwd); cd /usr/ascii/ || { echo "Error: /usr/ascii/ directory not found."; return 1; }; ./loopers.sh "$@"; cd "$original_dir" || { echo "Error: Unable to return to the original directory."; return 1; }; }

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
