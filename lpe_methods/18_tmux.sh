#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="tmux_screen"
info "Checking tmux/screen..."
# Root tmux sessions
for sock in /tmp/tmux-0/default /var/run/screen/S-root/*; do
    [ -S "$sock" ] 2>/dev/null && [ -r "$sock" ] && { result_json "$METHOD" "found" "Root session: $sock" ""; exit 0; }
done
# Writable tmux socket
[ -w /tmp/tmux-0 ] 2>/dev/null && { result_json "$METHOD" "partial" "Writable tmux dir" ""; exit 0; }
result_json "$METHOD" "skip" "No sessions"; exit 1
