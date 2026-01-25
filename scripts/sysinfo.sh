#!/bin/bash
K=$(uname -r)
A=$(uname -m)
H=$(hostname)
U=$(whoami)
I=$(id -u)
M=$(free -m 2>/dev/null|awk '/Mem:/{print $3"/"$2"M"}')
UP=$(uptime -p 2>/dev/null||uptime|sed 's/.*up/up/')
PK="no";[ -u /usr/bin/pkexec ]&&PK="SUID"
echo "{\"kernel\":\"$K\",\"arch\":\"$A\",\"host\":\"$H\",\"user\":\"$U\",\"uid\":\"$I\",\"mem\":\"$M\",\"uptime\":\"$UP\",\"pkexec\":\"$PK\"}"
