#!/usr/bin/env bash

# Network speedtest with complete stats for alias-hub.
# Combines link info, public IP/ISP, DNS timing, latency/loss,
# download/upload speed, and interface counters in one report.
#
# Speed backend: built-in parallel curl streams against Cloudflare's
# anycast edge by default (zero extra dependencies, stable everywhere).
# Flaky external tools (Ookla `speedtest`, `speedtest-cli`) are opt-in
# only via --backend.

set -o pipefail
export LC_ALL=C

readonly VERSION="1.1.0"
readonly PING_COUNT=4
readonly PING_TIMEOUT=10
readonly SPEED_TIMEOUT=120
readonly INFO_TIMEOUT=10
# Stable built-in backend: parallel curl streams against Cloudflare's
# anycast edge (no extra packages, saturates the link like real speedtests).
readonly STABLE_STREAMS=4
readonly STABLE_BYTES_PER_STREAM=25000000
readonly STABLE_UPLOAD_BYTES=10000000
readonly STABLE_UPLOAD_STREAMS=2

C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'
C_CYAN='\033[0;36m'

MODE_FULL=true
MODE_LATENCY_ONLY=false
MODE_SPEED_ONLY=false
NO_COLOR=false
JSON_OUT=false
BACKEND="stable"
SPEEDTEST_SERVER=""
BEST_PING_MS="N/A"

PING_TARGETS=("1.1.1.1" "8.8.8.8" "google.com")

log_info() { printf '%b[INFO]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
log_success() { printf '%b[OK]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_warn() { printf '%b[WARN]%b %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error() { printf '%b[ERROR]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

no_color() {
    C_RESET=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
    C_RED=''; C_BOLD=''; C_CYAN=''
}

usage() {
    local status="${1:-0}"
    printf '%bUsage:%b %s [OPTIONS]\n\n' "$C_BOLD" "$C_RESET" "$0"
    printf '%s\n' \
        'Complete network speedtest: latency, loss, download/upload, DNS, IP info.' \
        '' \
        'Options:' \
        '  --simple           Skip interface counters and vnstat (quick report).' \
        '  --latency-only     Only run ping/DNS checks, skip speedtest.' \
        '  --speed-only       Only run download/upload speed, skip ping sweep.' \
        '  --server ID        Pass server ID to Ookla/speedtest-cli (with --backend).' \
        '  --backend NAME     Speed backend: stable (default), ookla, speedtest-cli.' \
        '                     stable = built-in parallel curl streams, no extra install.' \
        '                     ookla / speedtest-cli = external tool, must be installed.' \
        '  --json             Emit machine-readable JSON summary at the end.' \
        '  --no-color         Disable colored output.' \
        '  -h, --help         Show this help message.' \
        '' \
        'Examples:' \
        '  netspeed' \
        '  netspeed --simple' \
        '  netspeed --latency-only' \
        '  netspeed --backend ookla --server 12345 --json'
    exit "$status"
}

while (($#)); do
    case "$1" in
        --simple) MODE_FULL=false ;;
        --latency-only) MODE_LATENCY_ONLY=true ;;
        --speed-only) MODE_SPEED_ONLY=true ;;
        --server) shift; [[ -n "${1:-}" ]] || { log_error "--server needs an ID."; usage 2; }; SPEEDTEST_SERVER="$1" ;;
        --server=*) SPEEDTEST_SERVER="${1#--server=}" ;;
        --backend) shift; [[ -n "${1:-}" ]] || { log_error "--backend needs a name."; usage 2; }; BACKEND="$1" ;;
        --backend=*) BACKEND="${1#--backend=}" ;;
        --json) JSON_OUT=true ;;
        --no-color) NO_COLOR=true ;;
        -h|--help) usage 0 ;;
        --) shift; (($# == 0)) || { log_error "Unexpected positional arguments: $*"; usage 2; }; break ;;
        *) log_error "Unknown option: $1"; usage 2 ;;
    esac
    shift
done

[[ "$NO_COLOR" == true || ! -t 1 ]] || true
[[ "$NO_COLOR" == true ]] && no_color

if [[ "$MODE_LATENCY_ONLY" == true && "$MODE_SPEED_ONLY" == true ]]; then
    log_error "--latency-only and --speed-only are mutually exclusive."
    exit 2
fi

case "$BACKEND" in
    stable|ookla|speedtest-cli) ;;
    *) log_error "Unknown backend: $BACKEND (use stable, ookla, or speedtest-cli)."; usage 2 ;;
esac

if [[ "$BACKEND" == "ookla" ]] && ! command -v speedtest >/dev/null 2>&1; then
    log_error "Backend 'ookla' requested but the 'speedtest' binary is not installed."
    exit 1
fi
if [[ "$BACKEND" == "speedtest-cli" ]] && ! command -v speedtest-cli >/dev/null 2>&1; then
    log_error "Backend 'speedtest-cli' requested but it is not installed (pip install speedtest-cli)."
    exit 1
fi

for cmd in ping ip awk grep sed curl; do
    command -v "$cmd" >/dev/null 2>&1 || { log_error "Required command not found: $cmd"; exit 1; }
done

section() { printf '\n%b== %s ==%b\n' "$C_BOLD$C_CYAN" "$1" "$C_RESET"; }

# --- collectors (globals for JSON summary) ---
PUB_IP=""; ISP=""; CITY=""
IFACE="N/A"; LOCAL_IP="N/A"; GATEWAY="N/A"; DNS_SERVERS="N/A"
DNS_TIME_MS="N/A"
DOWN_MBPS="N/A"; UP_MBPS="N/A"; SPEED_PING_MS="N/A"; SPEED_SERVER="N/A"; SPEED_BACKEND="N/A"

get_link_info() {
    local def_route
    def_route=$(ip route show default 2>/dev/null | head -n 1)
    GATEWAY=$(printf '%s' "$def_route" | awk '{ for (i=1;i<=NF;i++) if ($i=="via") print $(i+1) }' | head -n 1)
    IFACE=$(printf '%s' "$def_route" | awk '{ for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1) }' | head -n 1)
    [[ -n "$GATEWAY" ]] || GATEWAY="N/A"
    [[ -n "$IFACE" ]] || IFACE="N/A"
    if [[ "$IFACE" != "N/A" ]]; then
        LOCAL_IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet / { print $2 }' | cut -d/ -f1 | head -n 1)
        [[ -n "$LOCAL_IP" ]] || LOCAL_IP="N/A"
    fi
    DNS_SERVERS=$(awk '/^nameserver/ { print $2 }' /etc/resolv.conf 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')
    [[ -n "$DNS_SERVERS" ]] || DNS_SERVERS="N/A"
}

get_public_ip() {
    local info
    info=$(timeout --foreground --kill-after=5 "$INFO_TIMEOUT" curl -s https://ipinfo.io/json 2>/dev/null) || info=""
    if [[ -n "$info" ]] && command -v jq >/dev/null 2>&1 && printf '%s' "$info" | jq -e . >/dev/null 2>&1; then
        PUB_IP=$(printf '%s' "$info" | jq -r '.ip // empty') || PUB_IP=""
        ISP=$(printf '%s' "$info" | jq -r '.org // empty') || ISP=""
        CITY=$(printf '%s' "$info" | jq -r '"\(.city // ""), \(.country // "")"' | sed 's/^, //; s/, $//') || CITY=""
    fi
    # Fallbacks when ipinfo.io is blocked/empty (try IPv4 plain-text services).
    [[ -n "$PUB_IP" ]] || PUB_IP=$(timeout --foreground --kill-after=5 "$INFO_TIMEOUT" curl -s -4 https://api.ipify.org 2>/dev/null || echo "")
    [[ -n "$PUB_IP" ]] || PUB_IP=$(timeout --foreground --kill-after=5 "$INFO_TIMEOUT" curl -s https://ifconfig.me 2>/dev/null | grep -oE '[0-9a-fA-F:.]+' | head -n 1 || echo "")
    [[ -n "$PUB_IP" ]] || PUB_IP=$(timeout --foreground --kill-after=5 "$INFO_TIMEOUT" curl -s https://icanhazip.com 2>/dev/null | tr -d ' \n' || echo "")
    # ISP/location fallback via ip-api.com (plain HTTP, often unblocked).
    if [[ -z "$ISP" || "$ISP" == "N/A" ]]; then
        local cx
        cx=$(timeout --foreground --kill-after=5 "$INFO_TIMEOUT" curl -s "http://ip-api.com/json/${PUB_IP}?fields=status,isp,org,city,country" 2>/dev/null) || cx=""
        if [[ -n "$cx" ]] && command -v jq >/dev/null 2>&1 && printf '%s' "$cx" | jq -e '.status == "success"' >/dev/null 2>&1; then
            ISP=$(printf '%s' "$cx" | jq -r '"\(.isp // "") \(.org // "")"' | sed 's/ *$//')
            CITY=$(printf '%s' "$cx" | jq -r '"\(.city // ""), \(.country // "")"' | sed 's/^, //; s/, $//')
        fi
    fi
    [[ -n "$PUB_IP" ]] || PUB_IP="N/A (offline?)"
    [[ -n "$ISP" ]] || ISP="N/A"
    [[ -n "$CITY" && "$CITY" != "," ]] || CITY="N/A"
}

# Prints: avg_ms loss_pct ; sets globals indirectly via stdout parse
ping_target() {
    local target="$1"
    local out avg loss
    out=$(timeout --foreground --kill-after=5 "$PING_TIMEOUT" ping -c "$PING_COUNT" -W 2 "$target" 2>&1) || true
    if [[ -z "$out" ]]; then
        printf 'timeout 100\n'
        return 1
    fi
    loss=$(printf '%s' "$out" | grep -oE '[0-9]+% packet loss' | grep -oE '[0-9]+' | head -n 1)
    avg=$(printf '%s' "$out" | awk -F'/' '/^rtt / { print $5 }')
    [[ -n "$loss" ]] || loss="100"
    [[ -n "$avg" ]] || avg="timeout"
    printf '%s %s\n' "$avg" "$loss"
    [[ "$loss" != "100" ]]
}

# Ping one target, print its table row, track best average for the summary.
note_ping() {
    local label="$1" target="$2"
    local result avg loss status
    result=$(ping_target "$target" || true)
    avg=$(printf '%s' "$result" | awk '{ print $1 }')
    loss=$(printf '%s' "$result" | awk '{ print $2 }')
    if [[ "$loss" == "0" ]]; then status="${C_GREEN}ok${C_RESET}";
    elif [[ "$loss" == "100" || "$avg" == "timeout" ]]; then status="${C_RED}fail${C_RESET}";
    else status="${C_YELLOW}lossy${C_RESET}"; fi
    printf '%-14s %-12s %-10s %b\n' "$label" "$avg" "${loss}%" "$status"
    if [[ "$avg" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        if [[ "$BEST_PING_MS" == "N/A" ]] || (( $(awk -v a="$avg" -v b="$BEST_PING_MS" 'BEGIN { print (a < b) }') )); then
            BEST_PING_MS="$avg"
        fi
    fi
}

run_latency() {
    section "Latency & packet loss (${PING_COUNT} packets each)"
    printf '%-14s %-12s %-10s %s\n' "TARGET" "AVG (ms)" "LOSS" "STATUS"
    local t
    for t in "${PING_TARGETS[@]}"; do
        note_ping "$t" "$t"
    done
    # gateway ping (most relevant first-hop)
    if [[ "$GATEWAY" != "N/A" ]]; then
        note_ping "gateway($GATEWAY)" "$GATEWAY"
    fi
}

run_dns_timing() {
    section "DNS"
    printf 'Resolvers: %s\n' "$DNS_SERVERS"
    local start end elapsed
    if command -v dig >/dev/null 2>&1; then
        start=$(date +%s%N)
        timeout --foreground --kill-after=5 "$INFO_TIMEOUT" dig +short +time=5 +tries=1 google.com >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            end=$(date +%s%N)
            elapsed=$(( (end - start) / 1000000 ))
            DNS_TIME_MS="$elapsed"
            printf 'Resolve google.com: %s ms\n' "$elapsed"
        else
            printf 'Resolve google.com: %bfailed%b\n' "$C_RED" "$C_RESET"
        fi
    else
        log_warn "dig not found; skipping DNS timing."
    fi
}

# --- Stable built-in backend: parallel curl streams (default) ---
# N parallel downloads against Cloudflare's anycast edge; throughput =
# total bytes / wall-clock time. Multi-stream saturates the link the way
# real speedtests do; a single curl stream would underreport.
stable_download() {
    local tmpdir start end elapsed total=0 n=0 i f size
    tmpdir=$(mktemp -d -t netspeed-dl.XXXXXX) || return 1
    start=$(date +%s%N)
    for i in $(seq 1 "$STABLE_STREAMS"); do
        timeout --foreground --kill-after=10 "$SPEED_TIMEOUT" \
            curl -s -o /dev/null -w '%{size_download}' \
            "https://speed.cloudflare.com/__down?bytes=${STABLE_BYTES_PER_STREAM}&r=${RANDOM}${i}" \
            > "$tmpdir/$i" 2>/dev/null &
    done
    wait || true
    end=$(date +%s%N)
    for f in "$tmpdir"/*; do
        size=$(tr -cd '0-9' < "$f" 2>/dev/null)
        if [[ "$size" =~ ^[0-9]+$ ]] && ((size >= STABLE_BYTES_PER_STREAM / 2)); then
            total=$((total + size)); n=$((n + 1))
        fi
    done
    rm -rf "$tmpdir"
    ((n > 0)) || return 1
    elapsed=$((end - start))
    ((elapsed > 0)) || return 1
    DOWN_MBPS=$(awk -v b="$total" -v ns="$elapsed" 'BEGIN { printf "%.2f", (b * 8) / (ns / 1e9) / 1e6 }')
    SPEED_SERVER="speed.cloudflare.com (${n}/${STABLE_STREAMS} streams)"
    return 0
}

# Single-stream fallback mirrors (used only if parallel test fails).
# Each entry: "url|min_bytes". Slow/blocked mirrors are skipped gracefully.
STABLE_MIRRORS=(
    "https://proof.ovh.net/files/10Mb.dat|1000000"
    "https://ash-speed.hetzner.com/10MB.bin|1000000"
    "https://cachefly.cachefly.net/10mb.test|1000000"
)

stable_download_single() {
    local entry url min size start end elapsed
    for entry in "${STABLE_MIRRORS[@]}"; do
        url="${entry%%|*}"; min="${entry##*|}"
        start=$(date +%s%N)
        size=$(timeout --foreground --kill-after=10 "$SPEED_TIMEOUT" \
            curl -sL -o /dev/null -w '%{size_download}' "$url" 2>/dev/null) || continue
        end=$(date +%s%N)
        [[ "$size" =~ ^[0-9]+$ && "$size" -ge "$min" ]] || continue
        elapsed=$((end - start))
        ((elapsed > 0)) || continue
        DOWN_MBPS=$(awk -v b="$size" -v ns="$elapsed" 'BEGIN { printf "%.2f", (b * 8) / (ns / 1e9) / 1e6 }')
        SPEED_SERVER="$url (single-stream fallback)"
        return 0
    done
    return 1
}

# Upload: parallel POSTs of random payloads to Cloudflare's __up endpoint
# (random data defeats compression; parallel streams saturate uplink).
stable_upload() {
    local tmpdir upfile start end elapsed total=0 n=0 i f up
    tmpdir=$(mktemp -d -t netspeed-up.XXXXXX) || return 1
    upfile="$tmpdir/payload.bin"
    head -c "$STABLE_UPLOAD_BYTES" /dev/urandom > "$upfile" 2>/dev/null || { rm -rf "$tmpdir"; return 1; }
    start=$(date +%s%N)
    for i in $(seq 1 "$STABLE_UPLOAD_STREAMS"); do
        timeout --foreground --kill-after=10 "$SPEED_TIMEOUT" \
            curl -s -o /dev/null -w '%{size_upload}' -X POST \
            --data-binary "@$upfile" \
            "https://speed.cloudflare.com/__up?r=${RANDOM}${i}" \
            > "$tmpdir/up$i" 2>/dev/null &
    done
    wait || true
    end=$(date +%s%N)
    for f in "$tmpdir"/up*; do
        up=$(tr -cd '0-9' < "$f" 2>/dev/null)
        if [[ "$up" =~ ^[0-9]+$ ]] && ((up >= STABLE_UPLOAD_BYTES / 2)); then
            total=$((total + up)); n=$((n + 1))
        fi
    done
    rm -rf "$tmpdir"
    ((n > 0)) || return 1
    elapsed=$((end - start))
    ((elapsed > 0)) || return 1
    UP_MBPS=$(awk -v b="$total" -v ns="$elapsed" 'BEGIN { printf "%.2f", (b * 8) / (ns / 1e9) / 1e6 }')
    return 0
}

run_stable() {
    log_info "Backend: built-in stable (${STABLE_STREAMS}x parallel curl streams)..."
    if stable_download; then
        log_success "Download: ${DOWN_MBPS} Mbps"
    elif stable_download_single; then
        log_warn "Parallel test failed; single-stream result: ${DOWN_MBPS} Mbps"
    else
        log_error "Download test failed on all mirrors (offline?)."
        return 1
    fi
    if stable_upload; then
        log_success "Upload: ${UP_MBPS} Mbps"
    else
        UP_MBPS="N/A"
        log_warn "Upload test failed; reporting download-only."
    fi
    SPEED_PING_MS="$BEST_PING_MS"
    SPEED_BACKEND="stable-curl"
    return 0
}

# --- Opt-in external backends (kept for users who prefer them) ---
run_ookla() {
    local args=(--format=json)
    [[ -n "$SPEEDTEST_SERVER" ]] && args+=(--server-id="$SPEEDTEST_SERVER")
    local json
    json=$(timeout --foreground --kill-after=10 "$SPEED_TIMEOUT" speedtest "${args[@]}" 2>/dev/null) || return 1
    [[ -n "$json" ]] || return 1
    if command -v jq >/dev/null 2>&1; then
        DOWN_MBPS=$(printf '%s' "$json" | jq -r '(.download.bandwidth // 0) / 125000 | tostring')
        UP_MBPS=$(printf '%s' "$json" | jq -r '(.upload.bandwidth // 0) / 125000 | tostring')
        SPEED_PING_MS=$(printf '%s' "$json" | jq -r '(.ping.latency // empty)')
        SPEED_SERVER=$(printf '%s' "$json" | jq -r '"\(.server.name // "?") (\(.server.location // "?")) [\(.server.host // "?")] "')
    else
        DOWN_MBPS=$(printf '%s' "$json" | grep -oE '"bandwidth":[0-9]+' | head -n 1 | grep -oE '[0-9]+' | awk '{ print $1/125000 }')
    fi
    [[ -n "$DOWN_MBPS" ]] || return 1
    SPEED_BACKEND="ookla-speedtest"
    return 0
}

run_speedtest_cli() {
    local args=(--json)
    [[ -n "$SPEEDTEST_SERVER" ]] && args+=(--server "$SPEEDTEST_SERVER")
    local json
    json=$(timeout --foreground --kill-after=10 "$SPEED_TIMEOUT" speedtest-cli "${args[@]}" 2>/dev/null) || return 1
    [[ -n "$json" ]] || return 1
    if command -v jq >/dev/null 2>&1; then
        DOWN_MBPS=$(printf '%s' "$json" | jq -r '(.download // 0) / 1000000 | tostring')
        UP_MBPS=$(printf '%s' "$json" | jq -r '(.upload // 0) / 1000000 | tostring')
        SPEED_PING_MS=$(printf '%s' "$json" | jq -r '(.ping // empty)')
        SPEED_SERVER=$(printf '%s' "$json" | jq -r '"\(.server.sponsor // "?") (\(.server.name // "?"))"')
    else
        return 1
    fi
    SPEED_BACKEND="speedtest-cli"
    return 0
}

run_speed() {
    section "Download / upload speed"
    case "$BACKEND" in
        ookla)
            log_info "Backend: Ookla speedtest (opt-in)..."
            run_ookla && return 0
            log_error "Ookla speedtest failed."
            return 1
            ;;
        speedtest-cli)
            log_info "Backend: speedtest-cli (opt-in)..."
            run_speedtest_cli && return 0
            log_error "speedtest-cli failed."
            return 1
            ;;
        *)
            run_stable && return 0
            log_error "Stable backend failed (offline?)."
            return 1
            ;;
    esac
}

run_iface_stats() {
    section "Interface counters & errors"
    if [[ "$IFACE" != "N/A" ]]; then
        ip -s link show dev "$IFACE" 2>/dev/null || ip addr show dev "$IFACE"
    else
        ip -s link 2>/dev/null | head -n 30
    fi
    if command -v vnstat >/dev/null 2>&1 && [[ "$IFACE" != "N/A" ]]; then
        printf '\n'
        vnstat -i "$IFACE" -s 2>/dev/null || vnstat -s 2>/dev/null || true
    fi
}

print_summary() {
    section "Summary"
    printf '%-12s %s\n' "Public IP:" "$PUB_IP"
    printf '%-12s %s\n' "ISP:" "$ISP"
    printf '%-12s %s\n' "Location:" "$CITY"
    printf '%-12s %s (%s)\n' "Local:" "$LOCAL_IP" "$IFACE"
    printf '%-12s %s\n' "Gateway:" "$GATEWAY"
    printf '%-12s %s Mbps\n' "Download:" "$DOWN_MBPS"
    printf '%-12s %s Mbps\n' "Upload:" "$UP_MBPS"
    printf '%-12s %s ms\n' "Ping:" "$SPEED_PING_MS"
    printf '%-12s %s [%s]\n' "Server:" "$SPEED_SERVER" "$SPEED_BACKEND"
}

print_json() {
    printf '{"public_ip":"%s","isp":"%s","location":"%s","local_ip":"%s","iface":"%s","gateway":"%s","download_mbps":"%s","upload_mbps":"%s","ping_ms":"%s","server":"%s","backend":"%s"}\n' \
        "$PUB_IP" "$ISP" "$CITY" "$LOCAL_IP" "$IFACE" "$GATEWAY" "$DOWN_MBPS" "$UP_MBPS" "$SPEED_PING_MS" "$SPEED_SERVER" "$SPEED_BACKEND"
}

# --- main ---
printf '%bNetwork Speedtest v%s%b\n' "$C_BOLD" "$VERSION" "$C_RESET"

get_link_info
get_public_ip

section "Connection info"
printf '%-12s %s\n' "Public IP:" "$PUB_IP"
printf '%-12s %s\n' "ISP:" "$ISP"
printf '%-12s %s\n' "Location:" "$CITY"
printf '%-12s %s (%s)\n' "Local:" "$LOCAL_IP" "$IFACE"
printf '%-12s %s\n' "Gateway:" "$GATEWAY"
printf '%-12s %s\n' "DNS:" "$DNS_SERVERS"

if [[ "$MODE_SPEED_ONLY" != true ]]; then
    run_latency
    run_dns_timing
fi

if [[ "$MODE_LATENCY_ONLY" != true ]]; then
    if run_speed; then
        log_success "Speedtest complete."
    else
        log_warn "Speedtest incomplete; showing partial stats."
    fi
fi

if [[ "$MODE_FULL" == true && "$MODE_LATENCY_ONLY" != true && "$MODE_SPEED_ONLY" != true ]]; then
    run_iface_stats
fi

print_summary

[[ "$JSON_OUT" == true ]] && print_json
