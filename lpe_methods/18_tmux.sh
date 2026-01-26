#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="tmux"
info "Checking $M..."
result "$M" "skip" "Not implemented" ""; exit 1
