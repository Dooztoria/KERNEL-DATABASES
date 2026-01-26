#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking Redis..."

if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping 2>/dev/null | grep -q PONG; then
        success "Redis accessible without auth!"
        info=$(redis-cli info 2>/dev/null | head -20)
        echo "$info"
        warn "Potential RCE via Redis"
    else
        fail "Redis requires authentication"
    fi
elif [ -S /var/run/redis/redis.sock ]; then
    success "Redis socket found: /var/run/redis/redis.sock"
else
    fail "Redis not found"
fi
