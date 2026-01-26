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

# Check writable cron files
for f in /etc/crontab /etc/cron.d/*; do
    if [ -w "$f" ] 2>/dev/null; then
        success "WRITABLE: $f"
        found=1
    fi
done

# Check cron jobs running as root with writable scripts
crontab -l 2>/dev/null | grep -v '^#' | while read -r line; do
    script=$(echo "$line" | grep -oE '/[^ ]+')
    if [ -n "$script" ] && [ -w "$script" ] 2>/dev/null; then
        success "WRITABLE SCRIPT in cron: $script"
        found=1
    fi
done

if [ $found -eq 0 ]; then
    fail "No exploitable cron jobs found"
fi
