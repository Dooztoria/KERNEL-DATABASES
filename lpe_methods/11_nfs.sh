#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking NFS..."

if [ -r /etc/exports ] && grep -q "no_root_squash" /etc/exports 2>/dev/null; then
    success "VULNERABLE: no_root_squash!"
    grep "no_root_squash" /etc/exports
else
    fail "No NFS vulnerability"
fi
