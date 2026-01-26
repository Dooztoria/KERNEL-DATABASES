#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking SSH keys..."

found=0
for f in /root/.ssh/id_* /home/*/.ssh/id_*; do
    if [ -r "$f" ] 2>/dev/null && [[ ! "$f" == *.pub ]]; then
        success "READABLE KEY: $f"
        found=1
    fi
done
[ $found -eq 0 ] && fail "No readable SSH keys"
