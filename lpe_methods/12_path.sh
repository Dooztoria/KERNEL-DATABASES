#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking PATH hijacking..."

found=0
IFS=':' read -ra DIRS <<< "$PATH"
for d in "${DIRS[@]}"; do
    if [ -w "$d" ] 2>/dev/null; then
        success "WRITABLE PATH: $d"
        found=1
    fi
done
[ $found -eq 0 ] && fail "No writable PATH"
