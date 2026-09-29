#!/bin/bash
# 完成剩余更新：apt phased updates + snap refresh。若 apt 会删除任何包则停止。
LOG=~/ubuntu-audit-step7.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
PH=(-o APT::Get::Always-Include-Phased-Updates=true)

echo "=== apt update"; sudo apt-get update -q || exit 1
echo "=== simulate"
SIM=$(apt-get -s "${PH[@]}" full-upgrade)
echo "$SIM" | grep -E '^(Inst|Remv)'
R=$(echo "$SIM" | grep -c '^Remv'); echo "removals=$R"
[ "$R" -ne 0 ] && { echo "!!! 会删除软件包，已停止"; exit 2; }
echo "=== apt full-upgrade (incl. phased)"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y "${PH[@]}" full-upgrade || exit 3
sudo dpkg --audit; sudo apt-get check
echo "=== apt remaining:"; apt list --upgradable 2>/dev/null | tail -n +2

echo "=== snap refresh (请先关闭 Firefox / Thunderbird，否则它们会被推迟)"
sudo snap refresh
echo "=== snap remaining:"; snap refresh --list 2>&1
[ -f /var/run/reboot-required ] && { echo "REBOOT REQUIRED:"; cat /var/run/reboot-required.pkgs; }
echo "=== DONE $(date -Iseconds)"
