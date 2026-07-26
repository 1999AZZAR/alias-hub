#!/usr/bin/env bash

# System cleanup for Debian/Ubuntu systems.
# Destructive symlink removal is opt-in; package, cache, log, and temp cleanup
# remains bounded by per-operation timeouts.

set -o pipefail
export LC_ALL=C

readonly VERSION="5.0"
readonly APT_LOCK_WAIT=60
readonly COMMAND_TIMEOUT=300

C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'

DRY_RUN=false
REMOVE_BROKEN_SYMLINKS=false
WARNING_COUNT=0
ORIGINAL_ARGS=("$@")

log_info() { printf '%b[INFO]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
log_success() { printf '%b[OK]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_warn() {
    WARNING_COUNT=$((WARNING_COUNT + 1))
    printf '%b[WARN]%b %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2
}
log_error() { printf '%b[ERROR]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

usage() {
    local status="${1:-0}"
    printf '%bUsage:%b %s [OPTIONS]\n\n' "$C_BOLD" "$C_RESET" "$0"
    printf '%s\n' \
        'Options:' \
        '  -d, --dry-run                 Show actions without changing the system.' \
        '      --remove-broken-symlinks  Delete broken links instead of only reporting them.' \
        '  -h, --help                    Show this help message.' \
        '' \
        'Environment:' \
        '  SKIP_FLATPAK=1                Skip Flatpak cleanup.'
    exit "$status"
}

print_command() {
    printf '  %b[DRY-RUN]%b' "$C_YELLOW" "$C_RESET"
    printf ' %q' "$@"
    printf '\n'
}

run_timed() {
    local label="$1"
    local duration="$2"
    local status
    shift 2

    if timeout --kill-after=10 "$duration" "$@" >/dev/null 2>&1; then
        log_success "$label"
        return 0
    else
        status=$?
    fi

    if ((status == 124 || status == 137)); then
        log_warn "$label timed out after ${duration}s."
    else
        log_warn "$label failed (exit $status)."
    fi
    return "$status"
}

wait_for_apt_lock() {
    local waited=0
    local is_locked
    local lock
    local locks=(
        /var/lib/dpkg/lock
        /var/lib/dpkg/lock-frontend
        /var/lib/apt/lists/lock
        /var/cache/apt/archives/lock
    )

    if ! command -v fuser >/dev/null 2>&1; then
        log_warn "fuser is unavailable; APT will perform its own lock check."
        return 0
    fi

    while :; do
        is_locked=false
        for lock in "${locks[@]}"; do
            if fuser "$lock" >/dev/null 2>&1; then
                is_locked=true
                break
            fi
        done
        [[ "$is_locked" == true ]] || return 0
        if ((waited >= APT_LOCK_WAIT)); then
            log_warn "APT remained locked for ${APT_LOCK_WAIT}s; skipping this APT operation."
            return 1
        fi
        log_info "Waiting for the APT lock (${waited}s/${APT_LOCK_WAIT}s)..."
        sleep 5
        waited=$((waited + 5))
    done
}

get_available_space() {
    local available
    available=$(df --output=avail -B1 / 2>/dev/null | awk 'NR == 2 { print $1 }') || return 1
    [[ "$available" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$available"
}

format_bytes() {
    awk -v bytes="$1" 'BEGIN {
        split("B KB MB GB TB", units, " ")
        unit = 1
        while (bytes >= 1024 && unit < 5) { bytes /= 1024; unit++ }
        if (unit == 1) printf "%d %s", bytes, units[unit]
        else printf "%.2f %s", bytes, units[unit]
    }'
}

clean_directory_contents() {
    local target="$1"
    [[ -d "$target" ]] || return 0

    if [[ "$DRY_RUN" == true ]]; then
        print_command find "$target" -mindepth 1 -xdev -delete
    elif find "$target" -mindepth 1 -xdev -delete 2>/dev/null; then
        log_success "Cleaned $target."
    else
        log_warn "Could not completely clean $target."
    fi
}

clean_symlinks() {
    local directory="$1"
    local max_depth="$2"
    local count

    [[ -n "$directory" && -d "$directory" ]] || return 0
    log_info "Scanning $directory for broken links (maximum depth: $max_depth)..."

    if [[ "$DRY_RUN" == true ]]; then
        print_command find "$directory" -xdev -maxdepth "$max_depth" -xtype l -ignore_readdir_race -print
        return 0
    fi

    if [[ "$REMOVE_BROKEN_SYMLINKS" == true ]]; then
        count=$(timeout --kill-after=5 30 find "$directory" -xdev -maxdepth "$max_depth" \
            -xtype l -ignore_readdir_race -delete -printf . 2>/dev/null | wc -c) || {
            log_warn "Broken-link cleanup for $directory failed or timed out."
            return 1
        }
        ((count == 0)) || log_success "Removed $count broken link(s) from $directory."
    else
        count=$(timeout --kill-after=5 30 find "$directory" -xdev -maxdepth "$max_depth" \
            -xtype l -ignore_readdir_race -printf . 2>/dev/null | wc -c) || {
            log_warn "Broken-link scan for $directory failed or timed out."
            return 1
        }
        ((count == 0)) || log_warn "Found $count broken link(s) in $directory; use --remove-broken-symlinks to delete them."
    fi
}

while (($#)); do
    case "$1" in
        -d|--dry-run) DRY_RUN=true ;;
        --remove-broken-symlinks) REMOVE_BROKEN_SYMLINKS=true ;;
        -h|--help) usage 0 ;;
        --) shift; (($# == 0)) || { log_error "Unexpected positional arguments: $*"; usage 2; }; break ;;
        *) log_error "Unknown option: $1"; usage 2 ;;
    esac
    shift
done

if [[ "${SKIP_FLATPAK:-0}" != 0 && "${SKIP_FLATPAK:-0}" != 1 ]]; then
    log_error "SKIP_FLATPAK must be 0 or 1."
    exit 2
fi

if [[ "$EUID" -ne 0 && "$DRY_RUN" == false ]]; then
    command -v sudo >/dev/null 2>&1 || { log_error "Root privileges are required and sudo is unavailable."; exit 1; }
    printf '%bRoot privileges required; restarting with sudo.%b\n' "$C_YELLOW" "$C_RESET"
    exec sudo env SKIP_FLATPAK="${SKIP_FLATPAK:-0}" "$(readlink -f "$0")" "${ORIGINAL_ARGS[@]}"
fi

for required_command in timeout find df awk wc; do
    command -v "$required_command" >/dev/null 2>&1 || {
        log_error "Required command not found: $required_command"
        exit 1
    }
done

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$(id -un)"
fi
USER_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | awk -F: 'NR == 1 { print $6 }')
if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    log_warn "Cannot determine an accessible home for $TARGET_USER; user cleanup will be skipped."
    USER_HOME=""
fi

printf '%bSystem Cleanup v%s%b\n' "$C_BOLD" "$VERSION" "$C_RESET"
[[ "$DRY_RUN" == false ]] || printf '%bDry-run mode: no changes will be made.%b\n' "$C_YELLOW" "$C_RESET"
[[ "${SKIP_FLATPAK:-0}" == 0 ]] || printf '%bFlatpak cleanup disabled.%b\n' "$C_YELLOW" "$C_RESET"
printf 'Target user: %s\nHome: %s\n' "$TARGET_USER" "${USER_HOME:-N/A}"

initial_space=$(get_available_space || true)

printf '\n%b[1/7] APT packages and cache%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
    log_info "APT is unavailable; skipping."
elif [[ "$DRY_RUN" == true ]]; then
    print_command apt-get clean
    print_command apt-get autoremove --purge -y
    print_command apt-get autoclean
    log_info "Would purge packages left in the config-files state."
elif wait_for_apt_lock; then
    run_timed "APT cache cleaned." "$COMMAND_TIMEOUT" apt-get clean
    run_timed "Unused APT packages removed." "$COMMAND_TIMEOUT" apt-get autoremove --purge -y
    run_timed "Obsolete APT packages cleaned." "$COMMAND_TIMEOUT" apt-get autoclean

    mapfile -t leftover_packages < <(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' 2>/dev/null | awk '$1 ~ /^rc/ { print $2 }')
    if ((${#leftover_packages[@]})); then
        run_timed "Leftover package configurations purged." 180 apt-get purge -y -- "${leftover_packages[@]}"
    else
        log_info "No leftover package configurations found."
    fi
fi

printf '\n%b[2/7] Docker, Snap, and Flatpak%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if command -v docker >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        print_command docker system prune -af
    else
        run_timed "Unused Docker objects cleaned (volumes preserved)." 180 docker system prune -af
    fi
else
    log_info "Docker is unavailable; skipping."
fi

if command -v snap >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would remove disabled Snap revisions and clear /var/cache/snapd."
    else
        snap_failed=false
        while read -r snap_name revision; do
            [[ -n "$snap_name" && "$revision" =~ ^[0-9]+$ ]] || continue
            run_timed "Removed $snap_name revision $revision." 30 snap remove "$snap_name" --revision="$revision" || snap_failed=true
        done < <(snap list --all 2>/dev/null | awk '$6 == "disabled" { print $1, $3 }')
        clean_directory_contents /var/cache/snapd
        [[ "$snap_failed" == true ]] || log_success "Disabled Snap revisions cleaned."
    fi
else
    log_info "Snap is unavailable; skipping."
fi

if ! command -v flatpak >/dev/null 2>&1; then
    log_info "Flatpak is unavailable; skipping."
elif [[ "${SKIP_FLATPAK:-0}" == 1 ]]; then
    log_info "Flatpak cleanup skipped by configuration."
elif [[ "$DRY_RUN" == true ]]; then
    print_command flatpak uninstall --unused --system -y --noninteractive
    [[ -z "$USER_HOME" ]] || print_command sudo -H -u "$TARGET_USER" flatpak uninstall --unused --user -y --noninteractive
else
    run_timed "Unused system Flatpaks cleaned." 30 flatpak uninstall --unused --system -y --noninteractive
    if [[ -n "$USER_HOME" && "$TARGET_USER" != root ]]; then
        run_timed "Unused Flatpaks for $TARGET_USER cleaned." 30 sudo -H -u "$TARGET_USER" \
            flatpak uninstall --unused --user -y --noninteractive
    fi
fi

printf '\n%b[3/7] Logs and temporary files%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if [[ "$DRY_RUN" == true ]]; then
    print_command find /var/log -xdev -type f \( -name '*.gz' -o -name '*.1' -o -name '*.old' \) -delete
    print_command journalctl --vacuum-time=2weeks
    print_command find /tmp /var/tmp -xdev -type f -mtime +7 -delete
else
    if find /var/log -xdev -type f \( -name '*.gz' -o -name '*.1' -o -name '*.old' \) -delete 2>/dev/null; then
        log_success "Rotated logs cleaned."
    else
        log_warn "Some rotated logs could not be removed."
    fi
    command -v journalctl >/dev/null 2>&1 && run_timed "Journal entries older than two weeks removed." 60 journalctl --vacuum-time=2weeks
    if find /tmp /var/tmp -xdev -type f -mtime +7 -delete 2>/dev/null; then
        log_success "Temporary files older than seven days cleaned."
    else
        log_warn "Some old temporary files could not be removed."
    fi
fi

printf '\n%b[4/7] User caches%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if [[ -n "$USER_HOME" ]]; then
    cache_targets=(
        "$USER_HOME/.cache/thumbnails"
        "$USER_HOME/.local/share/Trash"
        "$USER_HOME/.cache/pip"
        "$USER_HOME/.cache/fontconfig"
        "$USER_HOME/.cache/yarn"
        "$USER_HOME/.npm/_cacache"
    )
    for target in "${cache_targets[@]}"; do
        clean_directory_contents "$target"
    done
else
    log_info "User cache cleanup skipped."
fi

printf '\n%b[5/7] Broken symbolic links%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
clean_symlinks "$USER_HOME" 6
clean_symlinks /etc 5
clean_symlinks /var 5
clean_symlinks /usr/local 5

printf '\n%b[6/7] Old kernels%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if ! command -v apt-get >/dev/null 2>&1; then
    log_info "APT is unavailable; skipping."
elif [[ "$DRY_RUN" == true ]]; then
    print_command apt-get autoremove --purge -y
elif wait_for_apt_lock; then
    run_timed "Kernel-related unused packages removed." "$COMMAND_TIMEOUT" apt-get autoremove --purge -y
fi

printf '\n%b[7/7] Orphaned packages%b\n' "$C_BOLD$C_BLUE" "$C_RESET"
if ! command -v deborphan >/dev/null 2>&1; then
    log_info "deborphan is unavailable; skipping."
elif [[ "$DRY_RUN" == true ]]; then
    print_command deborphan
    log_info "Would purge packages reported by deborphan."
elif wait_for_apt_lock; then
    mapfile -t orphaned_packages < <(deborphan 2>/dev/null)
    if ((${#orphaned_packages[@]})); then
        run_timed "Orphaned packages removed." 180 apt-get remove --purge -y -- "${orphaned_packages[@]}"
    else
        log_info "No orphaned packages found."
    fi
fi

final_space=$(get_available_space || true)
printf '\n%bSystem cleanup complete.%b\n' "$C_BOLD$C_GREEN" "$C_RESET"
if [[ "$DRY_RUN" == true ]]; then
    printf '%bNo changes were made.%b\n' "$C_YELLOW" "$C_RESET"
elif [[ "$initial_space" =~ ^[0-9]+$ && "$final_space" =~ ^[0-9]+$ ]]; then
    cleaned_space=$((final_space - initial_space))
    if ((cleaned_space > 0)); then
        printf 'Disk space freed: %b%s%b\n' "$C_GREEN" "$(format_bytes "$cleaned_space")" "$C_RESET"
    else
        log_info "No measurable disk space was freed."
    fi
else
    log_warn "Disk-space change could not be measured."
fi
((WARNING_COUNT == 0)) || printf '%bCompleted with %d warning(s).%b\n' "$C_YELLOW" "$WARNING_COUNT" "$C_RESET"
