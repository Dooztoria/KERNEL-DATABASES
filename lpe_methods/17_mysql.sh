#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking MySQL..."

if command -v mysql >/dev/null 2>&1; then
    if mysql -u root -e "SELECT 1" 2>/dev/null; then
        success "MySQL root without password!"
    else
        fail "MySQL requires auth"
    fi
else
    fail "MySQL not found"
fi
