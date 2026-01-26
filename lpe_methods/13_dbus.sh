#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="dbus"
info "Checking D-Bus..."
# Check for vulnerable polkit versions
pkexec --version 2>/dev/null|grep -qE "^0\." && { result_json "$METHOD" "vulnerable" "Old polkit" ""; exit 0; }
# Check writable dbus configs
[ -w /etc/dbus-1/system.d ] && { result_json "$METHOD" "partial" "Writable dbus config" ""; exit 0; }
result_json "$METHOD" "skip" "No D-Bus vuln"; exit 1
