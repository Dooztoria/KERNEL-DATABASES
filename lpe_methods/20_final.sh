#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="final_checks"
info "Final checks..."
findings=""
# World writable files owned by root
ww=$(find /etc /usr /opt -writable -user root -type f 2>/dev/null|head -3)
[ -n "$ww" ] && findings="$findings WW:$ww"
# SGID binaries
sgid=$(find / -perm -2000 -type f 2>/dev/null|head -3)
[ -n "$sgid" ] && findings="$findings SGID:$sgid"
# Writable /etc files
wetc=$(find /etc -writable -type f 2>/dev/null|head -3)
[ -n "$wetc" ] && findings="$findings ETC:$wetc"
[ -n "$findings" ] && { result_json "$METHOD" "found" "$findings" ""; exit 0; }
result_json "$METHOD" "done" "Scan complete" ""; exit 1
