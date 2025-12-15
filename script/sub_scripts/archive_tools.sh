# ==============================================================================
# ARCHIVE MANAGEMENT TOOLS
# ==============================================================================
# Functions for extracting and creating archives with automatic format detection.
#
# MODULE: archive_tools.sh
# LOCATION: script/sub_scripts/archive_tools.sh
# COMPATIBILITY: Bash, Zsh, and other POSIX-compliant shells
#
# FUNCTIONS:
# - extract() - Extract archives with automatic format detection
# - archive() - Create archives from files and directories
#
# SUPPORTED FORMATS:
# - Extract: tar.bz2, tar.gz, bz2, rar, gz, tar, zip, Z, 7z
# - Create: tar.gz, tar.bz2, tar, zip, 7z, rar
#
# ==============================================================================

# --- Extract archives ---
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

# --- Create archives ---
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

