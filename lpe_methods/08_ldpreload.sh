#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="ldpreload"
info "Checking LD_PRELOAD..."
sudo -n -l 2>/dev/null|grep -q "env_keep.*LD_PRELOAD" || { result "$M" "skip" "Not kept" ""; exit 1; }
result "$M" "partial" "LD_PRELOAD in env_keep" ""; exit 0
