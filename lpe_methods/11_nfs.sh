#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="nfs"
info "Checking NFS..."
[ -r /etc/exports ] && grep -q "no_root_squash" /etc/exports && {
    shares=$(grep "no_root_squash" /etc/exports|awk '{print $1}')
    result_json "$METHOD" "vulnerable" "no_root_squash: $shares" ""; exit 0
}
result_json "$METHOD" "skip" "No vulnerable NFS"; exit 1
