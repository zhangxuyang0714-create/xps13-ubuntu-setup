#!/bin/bash
# S0ix 排查 2：对嫌疑设备临时开启 runtime PM（control=auto），观察 PCH IP 门控与 SLP_S0。
# 仅本次开机有效；脚本结束自动恢复为 on。不改 GRUB/BIOS/睡眠模式。
LOG=~/ubuntu-audit-s0ix-rpm.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
DEVS="0000:00:13.0 0000:00:1d.0 0000:00:1c.0"   # ISH / 读卡器端口 / Thunderbolt 端口
P=/sys/kernel/debug/pmc_core

show() {
  for d in $DEVS; do echo "  $d control=$(cat /sys/bus/pci/devices/$d/power/control) runtime=$(cat /sys/bus/pci/devices/$d/power/runtime_status)"; done
  echo "  PCH IP On: $(sudo grep 'State: On' $P/pch_ip_power_gating_status | awk -F' - ' '{print $2}' | awk '{print $1}' | tr '\n' ' ')"
}

echo "=== before"; show
for d in $DEVS; do echo auto | sudo tee /sys/bus/pci/devices/$d/power/control >/dev/null; done
sleep 10
echo "=== after control=auto (awake, 10s)"; show

echo 1 | sudo tee /sys/power/pm_debug_messages >/dev/null
R0=$(sudo cat $P/slp_s0_residency_usec)
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo "slp_s0 before: $R0"
echo ">>> 现在请合盖，约 3 分钟后开盖。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do sleep 1; done
sleep 5
echo "slp_s0 after : $(sudo cat $P/slp_s0_residency_usec)"
echo "last_hw_sleep: $(cat /sys/power/suspend_stats/last_hw_sleep)"
journalctl -k --since "$SINCE" --no-pager -o short-iso | grep -iE 'SLP_S0|suspend entry|suspend exit' | head
journalctl -k --since "$SINCE" --no-pager | grep -E 'Timekeeping' | awk '{s+=$(NF-1)} END{print "total asleep s:", s}'
echo "=== awake after resume"; show

echo "=== restore control=on"
for d in $DEVS; do echo on | sudo tee /sys/bus/pci/devices/$d/power/control >/dev/null; done
echo 0 | sudo tee /sys/power/pm_debug_messages >/dev/null
show
echo "=== DONE"
