#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Scanning SUID binaries..."

# Known exploitable SUID binaries
exploitable=("python" "python3" "perl" "ruby" "bash" "sh" "find" "vim" "vi" "nmap" "less" "more" "nano" "cp" "mv" "awk" "env" "php")

found=0
while IFS= read -r bin; do
    name=$(basename "$bin")
    for e in "${exploitable[@]}"; do
        if [[ "$name" == *"$e"* ]]; then
            success "SUID: $bin"
            found=1
        fi
    done
done < <(find / -perm -4000 -type f 2>/dev/null)

if [ $found -eq 0 ]; then
    fail "No exploitable SUID binaries found"
else
    warn "Manual exploitation may be required"
    echo ""
    echo "GTFOBins: https://gtfobins.github.io/"
fi
