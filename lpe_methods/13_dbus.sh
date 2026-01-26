#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking D-Bus..."

if command -v busctl >/dev/null 2>&1; then
    busctl list 2>/dev/null | grep -q PolicyKit && warn "PolicyKit available"
else
    fail "busctl not available"
fi
