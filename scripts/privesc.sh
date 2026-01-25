#!/bin/bash
echo "=== PRIVESC CHECK ==="
echo
echo "[KERNEL]"
K=$(uname -r)
echo "  Version: $K"
[[ "$K" > "5.8" && "$K" < "5.17" ]] && echo "  [!] VULNERABLE: DirtyPipe CVE-2022-0847"
[[ "$K" < "4.9" ]] && echo "  [!] VULNERABLE: DirtyCOW CVE-2016-5195"
echo
echo "[SUID BINARIES]"
find / -perm -4000 -type f 2>/dev/null | while read f; do
    case "$f" in
        *pkexec*) echo "  [!] $f - CVE-2021-4034 PwnKit";;
        *vim*|*vi*) echo "  [!] $f - vim -c ':!/bin/sh'";;
        *find*) echo "  [!] $f - find . -exec /bin/sh \\;";;
        *nmap*) echo "  [!] $f - nmap --interactive";;
        *python*) echo "  [!] $f - python -c 'import os;os.system(\"/bin/sh\")'";;
        *perl*) echo "  [!] $f - perl -e 'exec \"/bin/sh\"'";;
        *) echo "  $f";;
    esac
done | head -30
echo
echo "[CAPABILITIES]"
getcap -r / 2>/dev/null | head -10
echo
echo "[WRITABLE FILES]"
[ -w /etc/passwd ] && echo "  [!] /etc/passwd is WRITABLE!"
[ -w /etc/shadow ] && echo "  [!] /etc/shadow is WRITABLE!"
[ -w /etc/crontab ] && echo "  [!] /etc/crontab is WRITABLE!"
