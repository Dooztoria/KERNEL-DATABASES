#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="systemd"
info "Checking $M..."
result "$M" "skip" "Not implemented" ""; exit 1
