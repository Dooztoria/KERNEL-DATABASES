#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="kernel"
info "Checking kernel..."
k=$(uname -r);maj=$(echo $k|cut -d. -f1);min=$(echo $k|cut -d. -f2)
[ "$maj" -eq 5 ] && [ "$min" -ge 8 ] && [ "$min" -le 16 ] && { result "$M" "vulnerable" "DirtyPipe" ""; exit 0; }
[ "$maj" -lt 4 ] && { result "$M" "vulnerable" "DirtyCOW" ""; exit 0; }
[ -f /usr/bin/pkexec ] && { result "$M" "vulnerable" "PwnKit" ""; exit 0; }
result "$M" "skip" "Patched" ""; exit 1
