#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking kernel vulnerabilities..."

kernel=$(uname -r)
major=$(echo "$kernel" | cut -d. -f1)
minor=$(echo "$kernel" | cut -d. -f2)

echo "Kernel: $kernel"
echo ""

vuln=0

# DirtyPipe (CVE-2022-0847) - 5.8 <= kernel < 5.16.11
if [ "$major" -eq 5 ] && [ "$minor" -ge 8 ] && [ "$minor" -lt 17 ]; then
    success "VULNERABLE: DirtyPipe (CVE-2022-0847)"
    vuln=1
fi

# DirtyCOW (CVE-2016-5195) - kernel < 4.8.3
if [ "$major" -lt 4 ] || ([ "$major" -eq 4 ] && [ "$minor" -lt 9 ]); then
    success "VULNERABLE: DirtyCOW (CVE-2016-5195)"
    vuln=1
fi

# PwnKit (CVE-2021-4034) - check polkit version
if [ -f /usr/bin/pkexec ]; then
    if pkexec --version 2>/dev/null | grep -qE '0\.[0-9]+'; then
        success "POTENTIALLY VULNERABLE: PwnKit (CVE-2021-4034)"
        vuln=1
    fi
fi

# Overlayfs (CVE-2021-3493)
if [ "$major" -eq 5 ] && [ "$minor" -lt 11 ]; then
    if grep -q overlay /proc/filesystems 2>/dev/null; then
        success "POTENTIALLY VULNERABLE: Overlayfs (CVE-2021-3493)"
        vuln=1
    fi
fi

if [ $vuln -eq 0 ]; then
    fail "No known kernel vulnerabilities detected"
else
    warn "Run specific exploit from Exploits tab"
fi
