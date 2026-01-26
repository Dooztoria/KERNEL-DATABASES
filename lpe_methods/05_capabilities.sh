#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking Linux capabilities..."

found=0
while IFS= read -r line; do
    if echo "$line" | grep -qE 'cap_setuid|cap_setgid|cap_dac_override|cap_sys_admin|cap_sys_ptrace'; then
        success "CAPABILITY: $line"
        found=1
    fi
done < <(getcap -r / 2>/dev/null)

if [ $found -eq 0 ]; then
    fail "No exploitable capabilities found"
else
    warn "Check GTFOBins for exploitation methods"
fi
