#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking LD_PRELOAD..."

if sudo -n -l 2>/dev/null | grep -q "env_keep.*LD_PRELOAD"; then
    success "VULNERABLE: LD_PRELOAD in sudo env_keep!"
    warn "Can hijack sudo commands"
else
    fail "No LD_PRELOAD vulnerability"
fi
