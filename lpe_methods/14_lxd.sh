#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking LXD/LXC..."

if groups 2>/dev/null | grep -qwE 'lxd|lxc'; then
    success "VULNERABLE: User in lxd/lxc group!"
    warn "Can mount host filesystem"
else
    fail "Not in lxd/lxc group"
fi
