#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="lxd"
info "Checking $M..."
result "$M" "skip" "Not implemented" ""; exit 1
