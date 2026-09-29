#!/bin/bash
# S0ix 排查 1：飞行模式（Wi-Fi + 蓝牙关闭）下合盖，看能否进入 SLP_S0。只开调试日志，不改其他设置。
LOG=~/ubuntu-audit-s0ix-airplane.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
echo "rfkill:"; rfkill -n -o TYPE,SOFT | sort -u
if rfkill -n -o SOFT | grep -q unblocked; then echo "!!! 请先在右上角打开飞行模式（Wi-Fi 和蓝牙都要关），再重新运行"; exit 1; fi
echo 1 | sudo tee /sys/power/pm_debug_messages >/dev/null
R0=$(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo "slp_s0 before: $R0"
echo ">>> 现在请合盖，约 3 分钟后开盖。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do sleep 1; done
sleep 5
echo "slp_s0 after : $(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)"
echo "last_hw_sleep: $(cat /sys/power/suspend_stats/last_hw_sleep)"
journalctl -k --since "$SINCE" --no-pager -o short-monotonic | grep -iE 'SLP_S0|Timekeeping|Triggering wakeup|suspend entry|suspend exit' | head
echo 0 | sudo tee /sys/power/pm_debug_messages >/dev/null
echo "=== DONE（测试完可关闭飞行模式）"
