#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking D-Bus..."

if command -v busctl >/dev/null 2>&1; then
    # Check for org.freedesktop.PolicyKit1
    if busctl list 2>/dev/null | grep -q PolicyKit; then
        warn "PolicyKit available - check for CVE-2021-3560"
    fi
    
    # List services
    services=$(busctl list 2>/dev/null | wc -l)
    info "D-Bus services: $services"
else
    fail "busctl not available"
fi
