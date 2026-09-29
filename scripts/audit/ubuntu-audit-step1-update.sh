#!/bin/bash
# Step 1: apt 索引更新 + 状态检查 + 安全的系统更新
# 规则：若模拟升级会删除任何软件包，则停止，不执行升级。
LOG=~/ubuntu-audit-step1.log
exec > >(tee "$LOG") 2>&1
set -u
export LC_ALL=C.UTF-8

echo "=== $(date -Iseconds) apt-get update"
sudo apt-get update || { echo "!!! apt-get update failed"; exit 1; }

echo "=== dpkg audit / held / broken"
sudo dpkg --audit
apt-mark showhold
sudo apt-get check

echo "=== simulate full-upgrade"
SIM=$(apt-get -s full-upgrade)
echo "$SIM" | grep -E '^(Inst|Remv|Conf)' | grep -v '^Conf'
echo "$SIM" | tail -1
REMOVALS=$(echo "$SIM" | grep -c '^Remv')
KERNEL=$(echo "$SIM" | grep -E '^Inst linux-(image|modules|headers)' || true)
echo "removals=$REMOVALS"
echo "kernel_changes: ${KERNEL:-none}"

if [ "$REMOVALS" -ne 0 ]; then
  echo "!!! 升级会删除软件包，已停止，等待人工判断"
  exit 2
fi

echo "=== full-upgrade (no removals)"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade || { echo "!!! upgrade failed"; exit 3; }

echo "=== post-check"
sudo dpkg --audit
sudo apt-get check
apt list --upgradable 2>/dev/null
[ -f /var/run/reboot-required ] && { echo "REBOOT REQUIRED:"; cat /var/run/reboot-required.pkgs; }
echo "=== DONE $(date -Iseconds)"
