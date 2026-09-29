#!/bin/bash
# 被动模式：等待 AC 断开 -> 记录 -> 等待用户合盖睡眠并唤醒 -> 检查
source <(sed -n '/^snap() {/,/^}/p' "$(dirname "$0")/ubuntu-audit-suspend-test.sh")
LOG=~/ubuntu-audit-suspend-battery.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
while [ "$(cat /sys/class/power_supply/AC/online)" = 1 ]; do sleep 2; done
sleep 5
echo "===== [battery] BEFORE $(date -Iseconds)"; snap
S0=$(cat /sys/power/suspend_stats/success); SINCE=$(date '+%Y-%m-%d %H:%M:%S')
until [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ]; do C0=$(cat /sys/class/power_supply/BAT0/charge_now); sleep 1; done
sleep 15
echo "===== [battery] AFTER $(date -Iseconds) charge_before_sleep=$C0"; snap
echo "===== upower"; upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E 'state|energy|percentage|capacity'
echo "===== journal"
journalctl --since "$SINCE" --no-pager -o short-iso | grep -iE 'PM:|suspend|sleep|Lid|kernel.*(error|fail|warn|i915|usb|ACPI)|bluetooth|hci0' | grep -vE 'Rejected send|fwupd' | head -80
echo "pm_wakeup_irq=$(cat /sys/power/pm_wakeup_irq)"
