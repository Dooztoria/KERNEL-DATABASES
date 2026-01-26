#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking SSH keys..."

found=0

# Check for readable private keys
for f in /root/.ssh/id_* /home/*/.ssh/id_* ~/.ssh/id_*; do
    if [ -r "$f" ] 2>/dev/null && [[ ! "$f" == *.pub ]]; then
        success "READABLE KEY: $f"
        found=1
    fi
done

# Check writable authorized_keys
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
    if [ -w "$f" ] 2>/dev/null; then
        success "WRITABLE authorized_keys: $f"
        found=1
    fi
done

# Check writable .ssh directories
for d in /root/.ssh /home/*/.ssh; do
    if [ -w "$d" ] 2>/dev/null; then
        success "WRITABLE .ssh: $d"
        found=1
    fi
done

if [ $found -eq 0 ]; then
    fail "No SSH key vulnerabilities"
fi
