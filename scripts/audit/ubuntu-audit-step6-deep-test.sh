#!/bin/bash
# 实验：临时切换到 deep (S3)，电池模式合盖测试掉电与唤醒后功能。
# 结束时自动切回 s2idle；即使中途出问题，重启也会恢复 s2idle。不修改 GRUB。
source <(sed -n '/^snap() {/,/^}/p' "$(dirname "$0")/ubuntu-audit-suspend-test.sh")
LOG=~/ubuntu-audit-deep-test.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
echo deep | sudo tee /sys/power/mem_sleep >/dev/null
echo "=== mem_sleep now: $(cat /sys/power/mem_sleep)"
if [ "$(cat /sys/class/power_supply/AC/online)" = 1 ]; then echo ">>> 请拔掉 AC 电源..."; fi
while [ "$(cat /sys/class/power_supply/AC/online)" = 1 ]; do sleep 2; done
sleep 5
echo "===== [deep] BEFORE $(date -Iseconds)"; snap
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
echo ">>> 现在请合盖，20～30 分钟后开盖（时间越长，掉电数据越准）。等待中..."
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do C0=$(cat /sys/class/power_supply/BAT0/charge_now); V0=$(cat /sys/class/power_supply/BAT0/voltage_now); sleep 1; done
C1=$(cat /sys/class/power_supply/BAT0/charge_now)
sleep 15
echo "===== [deep] AFTER $(date -Iseconds) charge_before=$C0 charge_after_resume=$C1 delta_uAh=$((C1-C0)) voltage_before=$V0"; snap
echo "===== journal"
journalctl --since "$SINCE" --no-pager -o short-iso | grep -iE 'PM:|suspend|Lid|ACPI: (PM|Waking)|kernel.*(error|fail|i915|usb|nvme|iwlwifi)|bluetooth|hci0' | grep -vE 'Rejected send|fwupd' | head -80
echo "pm_wakeup_irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)"
echo s2idle | sudo tee /sys/power/mem_sleep >/dev/null
echo "=== DONE. mem_sleep 已恢复: $(cat /sys/power/mem_sleep)"
