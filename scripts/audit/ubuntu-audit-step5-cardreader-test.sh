#!/bin/bash
# 实验：临时移除 RTS525A 读卡器（仅本次开机，重启恢复），测试能否进入 SLP_S0。
# 不修改 BIOS / GRUB / 睡眠模式。
LOG=~/ubuntu-audit-cardreader-test.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
DEV=/sys/bus/pci/devices/0000:3b:00.0
PORT=/sys/bus/pci/devices/0000:00:1d.0
[ -e $DEV ] || { echo "读卡器已不在（可能已移除）"; }
[ -e $DEV ] && { lspci -s 3b:00.0; echo 1 | sudo tee $DEV/remove >/dev/null; }
sleep 3
echo "=== after remove: device present? $([ -e $DEV ] && echo yes || echo no)"
echo "=== root port 1d.0 runtime: $(cat $PORT/power/runtime_status) control=$(cat $PORT/power/control)"
echo 1 | sudo tee /sys/power/pm_debug_messages >/dev/null
R0=$(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)
echo "=== slp_s0 before: $R0"
echo "=== pch_ip SPC (awake): $(sudo grep -E 'SPC' /sys/kernel/debug/pmc_core/pch_ip_power_gating_status)"
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo ">>> 现在请合盖，约 3 分钟后开盖。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do sleep 1; done
sleep 5
echo "=== slp_s0 after: $(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)"
echo "=== last_hw_sleep: $(cat /sys/power/suspend_stats/last_hw_sleep)"
journalctl -k --since "$SINCE" --no-pager -o short-monotonic | grep -iE 'SLP_S0|Timekeeping|Triggering wakeup|suspend entry|suspend exit|error|fail' | head -30
echo 0 | sudo tee /sys/power/pm_debug_messages >/dev/null
echo "=== DONE。恢复读卡器：重启，或执行 echo 1 | sudo tee /sys/bus/pci/rescan"
