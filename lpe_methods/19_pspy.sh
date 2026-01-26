#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Monitoring processes (10 seconds)..."

echo ""
echo "New processes:"
echo "=============="

# Simple process monitor
(
    seen=""
    end=$((SECONDS + 10))
    while [ $SECONDS -lt $end ]; do
        ps aux 2>/dev/null | while read -r line; do
            pid=$(echo "$line" | awk '{print $2}')
            cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++)printf "%s ",$i}')
            key="${pid}:${cmd}"
            if ! echo "$seen" | grep -qF "$key"; then
                user=$(echo "$line" | awk '{print $1}')
                echo "[$user] $cmd"
                seen="$seen$key\n"
            fi
        done
        sleep 0.5
    done
) | head -30

warn "Run longer monitoring manually for better results"
