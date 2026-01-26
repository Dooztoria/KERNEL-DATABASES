#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="kernel"
info "Checking kernel exploits..."
kernel=$(uname -r);major=$(echo $kernel|cut -d. -f1);minor=$(echo $kernel|cut -d. -f2)
# DirtyPipe CVE-2022-0847
if [ "$major" -eq 5 ] && [ "$minor" -ge 8 ] && [ "$minor" -le 16 ]; then
    result_json "$METHOD" "vulnerable" "DirtyPipe CVE-2022-0847" ""; exit 0
fi
# DirtyCOW CVE-2016-5195
if [ "$major" -lt 4 ] || ([ "$major" -eq 4 ] && [ "$minor" -lt 8 ]); then
    result_json "$METHOD" "vulnerable" "DirtyCOW CVE-2016-5195" ""; exit 0
fi
# PwnKit CVE-2021-4034
[ -f /usr/bin/pkexec ] && { pkexec --version 2>/dev/null|grep -qE '^0\.[0-9]+' && { result_json "$METHOD" "vulnerable" "PwnKit CVE-2021-4034" ""; exit 0; }; }
result_json "$METHOD" "skip" "Kernel $kernel not vulnerable"; exit 1
