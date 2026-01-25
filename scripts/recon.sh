#!/bin/bash
echo "=== SYSTEM ===" && uname -a
echo && echo "=== USER ===" && id
echo && echo "=== NETWORK ===" && (ip a 2>/dev/null || ifconfig 2>/dev/null) | grep -E 'inet |ether' | head -20
echo && echo "=== SUID BINARIES ===" && find /usr/bin /bin /usr/sbin /sbin -perm -4000 2>/dev/null | head -30
echo && echo "=== CAPABILITIES ===" && getcap -r /usr/bin 2>/dev/null | head -10
echo && echo "=== CRON ===" && cat /etc/crontab 2>/dev/null | head -20
echo && echo "=== WRITABLE ===" && find /etc /var -writable 2>/dev/null 2>/dev/null | head -20
echo && echo "=== PROCESSES ===" && ps aux 2>/dev/null | head -20
