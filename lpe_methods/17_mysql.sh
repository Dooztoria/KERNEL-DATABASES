#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="mysql"
info "Checking MySQL..."
pgrep -u root mysql &>/dev/null || pgrep -u root mariadbd &>/dev/null || { result_json "$METHOD" "skip" "MySQL not as root"; exit 1; }
# Check for passwordless root
mysql -u root -e "SELECT 1" 2>/dev/null && { result_json "$METHOD" "vulnerable" "MySQL root no password" ""; exit 0; }
# Check config files for passwords
for c in /etc/mysql/debian.cnf /root/.my.cnf; do
    [ -r "$c" ] && grep -q password "$c" && { result_json "$METHOD" "partial" "Found: $c" ""; exit 0; }
done
result_json "$METHOD" "skip" "No MySQL access"; exit 1
