#!/bin/bash
echo "=== FULL RECON ==="
echo
echo "[SYSTEM]"
uname -a
echo
echo "[USER]"
id
whoami
echo
echo "[NETWORK]"
ip a 2>/dev/null | grep -E 'inet |ether'
cat /etc/resolv.conf 2>/dev/null | grep nameserver
echo
echo "[PROCESSES]"
ps aux 2>/dev/null | head -20
echo
echo "[CRON]"
cat /etc/crontab 2>/dev/null
ls -la /etc/cron.* 2>/dev/null
echo
echo "[SUID]"
find / -perm -4000 2>/dev/null | head -30
echo
echo "[WRITABLE]"
find /etc /var -writable 2>/dev/null | head -20
echo
echo "[DONE]"
