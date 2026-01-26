#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Hunting for passwords..."

found=0

# History files
for f in ~/.bash_history ~/.zsh_history ~/.mysql_history; do
    if [ -r "$f" ] && [ -s "$f" ]; then
        hits=$(grep -iE 'pass|pwd|secret|key|token' "$f" 2>/dev/null | head -5)
        if [ -n "$hits" ]; then
            success "FOUND in $f:"
            echo "$hits"
            found=1
        fi
    fi
done

# Config files
for f in /etc/shadow ~/.ssh/id_rsa /var/www/*/.env /var/www/*/wp-config.php; do
    if [ -r "$f" ] 2>/dev/null; then
        success "READABLE: $f"
        found=1
    fi
done

# Environment
env 2>/dev/null | grep -iE 'pass|pwd|secret|key|token|api' | while read -r line; do
    success "ENV: $line"
    found=1
done

if [ $found -eq 0 ]; then
    fail "No obvious passwords found"
fi
