#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="redis"
info "Checking Redis..."
nc -z 127.0.0.1 6379 2>/dev/null || { result "$M" "skip" "Not running" ""; exit 1; }
redis-cli -h 127.0.0.1 INFO 2>/dev/null|grep -q redis_version && { result "$M" "vulnerable" "No auth" ""; exit 0; }
result "$M" "fail" "Auth required" ""; exit 1
