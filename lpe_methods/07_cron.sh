#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Checking cron jobs..."

found=0

# Check writable cron directories
for d in /etc/cron.d /etc/cron.daily /etc/cron.hourly /var/spool/cron/crontabs; do
    if [ -w "$d" ] 2>/dev/null; then
        success "WRITABLE: $d"
        found=1
    fi
done

# Check crontab
if crontab -l 2>/dev/null | grep -v '^#' | grep -q '.'; then
    info "User crontab entries:"
    crontab -l 2>/dev/null | grep -v '^#' | head -5
fi

[ $found -eq 0 ] && fail "No writable cron directories"
