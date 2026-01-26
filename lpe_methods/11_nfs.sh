#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="nfs"
info "Checking $M..."
result "$M" "skip" "Not implemented" ""; exit 1
