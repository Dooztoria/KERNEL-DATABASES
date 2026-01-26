#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Hunting passwords..."

found=0

# History files
for f in ~/.bash_history ~/.mysql_history; do
    if [ -r "$f" ] && [ -s "$f" ]; then
        hits=$(grep -iE 'pass|pwd|secret|token' "$f" 2>/dev/null | head -3)
        if [ -n "$hits" ]; then
            success "Found in $f"
            found=1
        fi
    fi
done

# Readable shadow
[ -r /etc/shadow ] && success "READABLE: /etc/shadow" && found=1

# Environment
env 2>/dev/null | grep -iE 'pass|secret|key|token' | head -3 | while read -r line; do
    success "ENV: $line"
    found=1
done

[ $found -eq 0 ] && fail "No passwords found"
