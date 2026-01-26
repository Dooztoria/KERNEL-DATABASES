#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking NFS..."

if [ -r /etc/exports ]; then
    if grep -q "no_root_squash" /etc/exports 2>/dev/null; then
        success "VULNERABLE: no_root_squash found!"
        grep "no_root_squash" /etc/exports
        echo ""
        echo "Exploit: Mount share, create SUID binary as root"
    else
        fail "no_root_squash not found"
    fi
else
    fail "/etc/exports not readable"
fi

# Check mounted NFS
mount 2>/dev/null | grep nfs | while read -r line; do
    warn "NFS mounted: $line"
done
