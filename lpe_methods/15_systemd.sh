#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking systemd..."

found=0
for d in /etc/systemd/system /lib/systemd/system; do
    if [ -w "$d" ] 2>/dev/null; then
        success "WRITABLE: $d"
        found=1
    fi
done
[ $found -eq 0 ] && fail "No writable systemd dirs"
