#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking Redis..."

if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping 2>/dev/null | grep -q PONG; then
        success "Redis accessible without auth!"
    else
        fail "Redis requires auth"
    fi
else
    fail "Redis not found"
fi
