#!/bin/bash
echo "=== SYSTEM ===" && uname -a
echo && echo "=== USER ===" && id
echo && echo "=== NETWORK ===" && (ip a 2>/dev/null||ifconfig)|grep -E 'inet |ether'
echo && echo "=== SUID ===" && find /usr/bin /bin -perm -4000 2>/dev/null
echo && echo "=== SUDO ===" && sudo -l 2>/dev/null
echo && echo "=== CRON ===" && cat /etc/crontab 2>/dev/null && ls -la /etc/cron.d/ 2>/dev/null
echo && echo "=== WRITABLE ===" && find /etc /var/www -writable 2>/dev/null|head -20
