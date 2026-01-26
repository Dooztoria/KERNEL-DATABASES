#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking tmux/screen sessions..."

found=0

# Tmux
for sock in /tmp/tmux-*/default /tmp/tmux-*/*; do
    if [ -S "$sock" ] 2>/dev/null; then
        owner=$(stat -c '%U' "$sock" 2>/dev/null)
        if [ "$owner" = "root" ]; then
            success "ROOT tmux socket: $sock"
            found=1
        else
            warn "Tmux socket ($owner): $sock"
        fi
    fi
done

# Screen
for sock in /var/run/screen/S-*/*; do
    if [ -S "$sock" ] 2>/dev/null; then
        owner=$(stat -c '%U' "$(dirname "$sock")" 2>/dev/null | sed 's/S-//')
        success "Screen session: $sock (owner: $owner)"
        found=1
    fi
done

if [ $found -eq 0 ]; then
    fail "No tmux/screen sessions found"
fi
