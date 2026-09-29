#!/bin/bash
# 打开 PM 调试日志（仅本次开机有效，只影响日志），等待一次合盖睡眠/唤醒，收集内核报告。
LOG=~/ubuntu-audit-s0ix-trace.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
echo 1 | sudo tee /sys/power/pm_debug_messages >/dev/null
echo 1 | sudo tee /sys/module/intel_pmc_core/parameters/warn_on_s0ix_failures >/dev/null
echo "pm_debug_messages=$(cat /sys/power/pm_debug_messages) warn_on_s0ix_failures=$(cat /sys/module/intel_pmc_core/parameters/warn_on_s0ix_failures)"
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo ">>> 现在请合盖，约 3 分钟后开盖。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do sleep 1; done
sleep 5
echo "=== slp_s0_residency_usec: $(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)"
echo "=== last_hw_sleep: $(cat /sys/power/suspend_stats/last_hw_sleep)"
echo "=== kernel log during suspend"
journalctl -k --since "$SINCE" --no-pager -o short-monotonic | grep -vE 'fwupd' | head -300
echo 0 | sudo tee /sys/power/pm_debug_messages >/dev/null
echo "=== DONE (pm_debug_messages 已关回 0)"
