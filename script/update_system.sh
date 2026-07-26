#!/usr/bin/env bash

# Bounded system updates for Debian/Ubuntu, Snap, Flatpak, Homebrew, and fwupd.

set -o pipefail
export LC_ALL=C

readonly VERSION="4.0"
readonly APT_LOCK_WAIT=60

C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'

DRY_RUN=false
FULL_UPGRADE=false
FAILURE_COUNT=0
WARNING_COUNT=0
ORIGINAL_ARGS=("$@")

log_info() { printf '%b[INFO]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
log_success() { printf '%b[OK]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_warn() {
    WARNING_COUNT=$((WARNING_COUNT + 1))
    printf '%b[WARN]%b %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2
}
log_error() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf '%b[ERROR]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2
}

usage() {
    local status="${1:-0}"
    printf '%bUsage:%b %s [OPTIONS]\n\n' "$C_BOLD" "$C_RESET" "$0"
    printf '%s\n' \
        'Options:' \
        '  -d, --dry-run  Show update commands without changing the system.' \
        '  -f, --full     Use apt-get full-upgrade instead of upgrade.' \
        '  -h, --help     Show this help message.'
    exit "$status"
}

print_command() {
    printf '  %b[DRY-RUN]%b' "$C_YELLOW" "$C_RESET"
    printf ' %q' "$@"
    printf '\n'
}

run_update() {
    local label="$1"
    local duration="$2"
    local status
    shift 2

    if [[ "$DRY_RUN" == true ]]; then
        print_command "$@"
        return 0
    fi

    if timeout --foreground --kill-after=15 "$duration" "$@"; then
        log_success "$label"
        return 0
    else
        status=$?
    fi

    if ((status == 124 || status == 137)); then
        log_error "$label timed out after ${duration}s."
    else
        log_error "$label failed (exit $status)."
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
            log_error "APT remained locked for ${APT_LOCK_WAIT}s."
            return 1
        fi
        log_info "Waiting for the APT lock (${waited}s/${APT_LOCK_WAIT}s)..."
        sleep 5
        waited=$((waited + 5))
    done
}

header() {
    printf '\n%b[%s/5] %s%b\n' "$C_BOLD$C_BLUE" "$1" "$2" "$C_RESET"
}

while (($#)); do
    case "$1" in
        -d|--dry-run) DRY_RUN=true ;;
        -f|--full) FULL_UPGRADE=true ;;
        -h|--help) usage 0 ;;
        --) shift; (($# == 0)) || { printf '%b[ERROR]%b Unexpected positional arguments: %s\n' "$C_RED" "$C_RESET" "$*" >&2; usage 2; }; break ;;
        *) printf '%b[ERROR]%b Unknown option: %s\n' "$C_RED" "$C_RESET" "$1" >&2; usage 2 ;;
    esac
    shift
done

if [[ "$EUID" -ne 0 && "$DRY_RUN" == false ]]; then
    command -v sudo >/dev/null 2>&1 || { printf '%b[ERROR]%b Root privileges are required and sudo is unavailable.\n' "$C_RED" "$C_RESET" >&2; exit 1; }
    printf '%bRoot privileges required; restarting with sudo.%b\n' "$C_YELLOW" "$C_RESET"
    exec sudo "$(readlink -f "$0")" "${ORIGINAL_ARGS[@]}"
fi

for required_command in timeout id getent awk; do
    command -v "$required_command" >/dev/null 2>&1 || {
        printf '%b[ERROR]%b Required command not found: %s\n' "$C_RED" "$C_RESET" "$required_command" >&2
        exit 1
    }
done

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$(id -un)"
fi
USER_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | awk -F: 'NR == 1 { print $6 }')
RUN_AS_USER=()
if [[ "$TARGET_USER" != root ]]; then
    if command -v sudo >/dev/null 2>&1; then
        RUN_AS_USER=(sudo -H -u "$TARGET_USER")
    elif command -v runuser >/dev/null 2>&1; then
        RUN_AS_USER=(runuser -u "$TARGET_USER" -- env HOME="$USER_HOME")
    else
        log_warn "Cannot run user-scoped updates for $TARGET_USER; sudo and runuser are unavailable."
    fi
fi

printf '%bSmart System Update v%s%b\n' "$C_BOLD" "$VERSION" "$C_RESET"
[[ "$DRY_RUN" == false ]] || printf '%bDry-run mode: no changes will be made.%b\n' "$C_YELLOW" "$C_RESET"
printf 'Target user: %s\n' "$TARGET_USER"

header 1 "APT packages"
if ! command -v apt-get >/dev/null 2>&1; then
    log_warn "APT is unavailable; skipping."
elif [[ "$DRY_RUN" == true ]] || wait_for_apt_lock; then
    if run_update "APT package indexes refreshed." 300 env DEBIAN_FRONTEND=noninteractive apt-get update; then
        if [[ "$FULL_UPGRADE" == true ]]; then
            apt_upgrade=(apt-get full-upgrade -y)
            apt_upgrade_label="APT full upgrade completed."
        else
            apt_upgrade=(apt-get upgrade -y)
            apt_upgrade_label="APT upgrade completed."
        fi

        if run_update "$apt_upgrade_label" 1800 env DEBIAN_FRONTEND=noninteractive "${apt_upgrade[@]}"; then
            run_update "Unused APT packages removed." 600 env DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
        else
            log_warn "Skipping APT autoremove because the upgrade failed."
        fi

        if [[ "$DRY_RUN" == false ]] && command -v apt >/dev/null 2>&1; then
            upgradable_count=$(apt list --upgradable 2>/dev/null | awk 'NR > 1 { count++ } END { print count + 0 }')
            ((upgradable_count == 0)) || log_warn "$upgradable_count package(s) remain upgradable, possibly due to phasing or dependency constraints."
        fi
    else
        log_warn "Skipping APT upgrade because package indexes could not be refreshed."
    fi
fi

header 2 "Snap packages"
if command -v snap >/dev/null 2>&1; then
    run_update "Snap packages refreshed." 900 snap refresh
else
    log_info "Snap is unavailable; skipping."
fi

header 3 "Flatpak packages"
if command -v flatpak >/dev/null 2>&1; then
    run_update "System Flatpaks updated." 900 flatpak update --system -y --noninteractive
    if ((${#RUN_AS_USER[@]})); then
        run_update "Flatpaks for $TARGET_USER updated." 900 "${RUN_AS_USER[@]}" \
            flatpak update --user -y --noninteractive
    fi
else
    log_info "Flatpak is unavailable; skipping."
fi

header 4 "Homebrew packages"
BREW_CMD=""
for brew_candidate in \
    "${USER_HOME:+$USER_HOME/.linuxbrew/bin/brew}" \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$(command -v brew 2>/dev/null || true)"; do
    if [[ -n "$brew_candidate" && -x "$brew_candidate" ]]; then
        BREW_CMD="$brew_candidate"
        break
    fi
done

if [[ -z "$BREW_CMD" ]]; then
    log_info "Homebrew is unavailable for $TARGET_USER; skipping."
elif ((${#RUN_AS_USER[@]} == 0)); then
    log_warn "Homebrew cannot run as root or without a user-switching command; skipping."
else
    run_update "Homebrew metadata updated." 600 "${RUN_AS_USER[@]}" "$BREW_CMD" update
    run_update "Homebrew packages upgraded." 1800 "${RUN_AS_USER[@]}" "$BREW_CMD" upgrade
    run_update "Homebrew cache cleaned." 600 "${RUN_AS_USER[@]}" "$BREW_CMD" cleanup
fi

header 5 "Firmware"
if ! command -v fwupdmgr >/dev/null 2>&1; then
    log_info "fwupdmgr is unavailable; skipping."
elif [[ "$DRY_RUN" == true ]]; then
    print_command fwupdmgr refresh --force
    print_command fwupdmgr get-updates
    print_command fwupdmgr update -y
else
    run_update "Firmware metadata refreshed." 300 fwupdmgr refresh --force
    if timeout --foreground --kill-after=15 300 fwupdmgr get-updates; then
        run_update "Firmware updates applied." 1800 fwupdmgr update -y
    else
        firmware_status=$?
        if ((firmware_status == 2)); then
            log_info "No firmware updates are available."
        elif ((firmware_status == 124 || firmware_status == 137)); then
            log_error "Firmware update check timed out."
        else
            log_error "Firmware update check failed (exit $firmware_status)."
        fi
    fi
fi

printf '\n'
if ((FAILURE_COUNT > 0)); then
    printf '%bUpdate finished with %d failed step(s) and %d warning(s).%b\n' "$C_RED$C_BOLD" "$FAILURE_COUNT" "$WARNING_COUNT" "$C_RESET" >&2
    exit 1
fi

printf '%bSystem update complete.%b\n' "$C_GREEN$C_BOLD" "$C_RESET"
((WARNING_COUNT == 0)) || printf '%bCompleted with %d warning(s).%b\n' "$C_YELLOW" "$WARNING_COUNT" "$C_RESET"
if [[ -f /var/run/reboot-required ]]; then
    printf '%bReboot required.%b\n' "$C_RED$C_BOLD" "$C_RESET"
fi
