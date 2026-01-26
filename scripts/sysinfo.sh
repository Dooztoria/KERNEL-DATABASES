#!/bin/bash
h=$(hostname 2>/dev/null || echo "unknown")
i=$(hostname -I 2>/dev/null | awk '{print $1}')
k=$(uname -r 2>/dev/null)
a=$(uname -m 2>/dev/null)
u=$(whoami 2>/dev/null)
ui=$(id -u 2>/dev/null)
up=$(uptime -p 2>/dev/null | sed 's/up //')
m=$(free -h 2>/dev/null | awk '/Mem:/{print $3"/"$2}')
d=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
echo "{\"hostname\":\"$h\",\"ip\":\"$i\",\"kernel\":\"$k\",\"arch\":\"$a\",\"user\":\"$u\",\"uid\":\"$ui\",\"uptime\":\"$up\",\"mem\":\"$m\",\"disk\":\"$d\"}"
