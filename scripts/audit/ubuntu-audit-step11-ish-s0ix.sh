#!/bin/bash
# S0ix 排查 3：临时解绑 ISH（传感器集线器）驱动，观察 PCH IP 门控与 SLP_S0。
# 结束自动重新绑定；重启也会恢复。不改 GRUB/BIOS/睡眠模式。
LOG=~/ubuntu-audit-s0ix-ish.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
DEV=0000:00:13.0; DRV=/sys/bus/pci/drivers/intel_ish_ipc; P=/sys/kernel/debug/pmc_core
ipon() { sudo grep 'State: On' $P/pch_ip_power_gating_status | awk -F' - ' '{print $2}' | awk '{print $1}' | tr '\n' ' '; }

echo "=== before: driver=$(basename $(readlink /sys/bus/pci/devices/$DEV/driver)) | PCH IP On: $(ipon)"
echo $DEV | sudo tee $DRV/unbind >/dev/null
sleep 10
echo "=== after unbind: driver=$(readlink /sys/bus/pci/devices/$DEV/driver || echo none) runtime=$(cat /sys/bus/pci/devices/$DEV/power/runtime_status) | PCH IP On: $(ipon)"

echo 1 | sudo tee /sys/power/pm_debug_messages >/dev/null
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo "slp_s0 before: $(sudo cat $P/slp_s0_residency_usec)"
echo ">>> 现在请合盖，约 3 分钟后开盖。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do sleep 1; done
sleep 5
echo "slp_s0 after : $(sudo cat $P/slp_s0_residency_usec)"
echo "last_hw_sleep: $(cat /sys/power/suspend_stats/last_hw_sleep)"
journalctl -k --since "$SINCE" --no-pager -o short-iso | grep -iE 'SLP_S0|suspend entry|suspend exit' | head
journalctl -k --since "$SINCE" --no-pager | grep -E 'Timekeeping' | awk '{s+=$(NF-1)} END{print "total asleep s:", s}'
echo "=== awake after resume | PCH IP On: $(ipon)"

echo "=== rebind ISH"
echo $DEV | sudo tee $DRV/bind >/dev/null
sleep 5
echo 0 | sudo tee /sys/power/pm_debug_messages >/dev/null
echo "driver=$(basename $(readlink /sys/bus/pci/devices/$DEV/driver)) | sensors: $(cat /sys/bus/iio/devices/*/name 2>/dev/null | grep -cvE 'trigger|dev[0-9]')"
echo "=== DONE"
