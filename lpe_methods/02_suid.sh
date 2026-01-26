#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Scanning SUID binaries..."

found=0
dangerous_bins="bash|sh|python|perl|ruby|vim|vi|nano|less|more|awk|nmap|find|cp|mv|env|date|php|node|lua|tclsh|wish|gdb|strace|ltrace"

while IFS= read -r f; do
    [ -z "$f" ] && continue
    name=$(basename "$f")
    
    if echo "$name" | grep -qE "^($dangerous_bins)$"; then
        success "VULNERABLE SUID: $f"
        found=1
    else
        echo "[+] SUID: $f"
    fi
done < <(find / -perm -4000 -type f 2>/dev/null)

if [ $found -eq 1 ]; then
    warn "Manual exploitation may be required"
    warn "GTFOBins: https://gtfobins.github.io/"
else
    fail "No obviously exploitable SUID binaries"
fi
