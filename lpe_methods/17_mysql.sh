#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking MySQL..."

if command -v mysql >/dev/null 2>&1; then
    # Try passwordless root
    if mysql -u root -e "SELECT 1" 2>/dev/null; then
        success "VULNERABLE: MySQL root without password!"
        
        # Check plugin dir
        plugin_dir=$(mysql -u root -e "SHOW VARIABLES LIKE 'plugin_dir'" 2>/dev/null | tail -1 | awk '{print $2}')
        if [ -w "$plugin_dir" ] 2>/dev/null; then
            success "WRITABLE plugin dir: $plugin_dir"
            warn "UDF exploitation possible"
        fi
    else
        fail "MySQL root requires password"
    fi
else
    fail "MySQL client not found"
fi
