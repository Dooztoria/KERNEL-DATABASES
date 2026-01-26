#!/bin/bash
source "$(dirname "$0")/00_common.sh"
info "Monitoring processes (5 seconds)..."

end=$((SECONDS + 5))
while [ $SECONDS -lt $end ]; do
    ps aux 2>/dev/null | grep -E '^root' | grep -v '\[' | head -3
    sleep 1
done
warn "Run longer for better results"
