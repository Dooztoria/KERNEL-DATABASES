#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Running final checks..."

echo "=== World-writable files ==="
find /etc /usr -perm -0002 -type f 2>/dev/null | head -5

echo "=== SGID binaries ==="
find /usr -perm -2000 -type f 2>/dev/null | head -5

info "Manual review recommended"
