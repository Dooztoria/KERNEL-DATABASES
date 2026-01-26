#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Running final checks..."

echo ""
echo "=== World-writable files ==="
find /etc /usr /var -perm -0002 -type f 2>/dev/null | head -10

echo ""
echo "=== SGID binaries ==="
find / -perm -2000 -type f 2>/dev/null | head -10

echo ""
echo "=== Interesting files ==="
ls -la /etc/passwd /etc/shadow /etc/sudoers 2>/dev/null

echo ""
echo "=== Processes as root ==="
ps aux 2>/dev/null | grep "^root" | grep -vE 'kworker|migration|watchdog|\[' | head -10

info "Manual review recommended"
