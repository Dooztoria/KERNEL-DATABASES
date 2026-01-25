#!/bin/bash
K=$(uname -r)
A=$(uname -m)
H=$(hostname 2>/dev/null || echo "?")
U=$(whoami 2>/dev/null || echo "?")
I=$(id -u 2>/dev/null || echo "?")
M=$(free -m 2>/dev/null | awk '/Mem:/{print $3"/"$2"M"}' || echo "?")
UP=$(uptime -p 2>/dev/null | sed 's/up //' || echo "?")
PK="no"
[ -u /usr/bin/pkexec ] 2>/dev/null && PK="SUID"
echo "{\"kernel\":\"$K\",\"arch\":\"$A\",\"host\":\"$H\",\"user\":\"$U\",\"uid\":\"$I\",\"mem\":\"$M\",\"uptime\":\"$UP\",\"pkexec\":\"$PK\"}"
