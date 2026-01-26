#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking systemd..."

found=0

# Check writable service files
for d in /etc/systemd/system /lib/systemd/system; do
    if [ -w "$d" ] 2>/dev/null; then
        success "WRITABLE: $d"
        found=1
    fi
    
    for f in "$d"/*.service; do
        if [ -w "$f" ] 2>/dev/null; then
            success "WRITABLE SERVICE: $f"
            found=1
        fi
    done
done

# Check timer exploitation
systemctl list-timers 2>/dev/null | grep -v "^NEXT" | head -5

if [ $found -eq 0 ]; then
    fail "No writable systemd files"
fi
