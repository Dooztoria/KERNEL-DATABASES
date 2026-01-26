#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking tmux/screen..."

found=0
for sock in /tmp/tmux-*/default; do
    if [ -S "$sock" ] 2>/dev/null; then
        success "Tmux socket: $sock"
        found=1
    fi
done
[ $found -eq 0 ] && fail "No sessions found"
