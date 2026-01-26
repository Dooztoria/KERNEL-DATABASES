#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="passwords"
info "Hunting passwords..."
found=0
for f in /home/*/.bash_history /root/.bash_history /var/www/*/.env /var/www/*/wp-config.php; do
    [ -r "$f" ] 2>/dev/null && found=$((found+1))
done
[ $found -gt 0 ] && { result "$M" "partial" "Found $found files" ""; exit 0; }
result "$M" "skip" "No files" ""; exit 1
