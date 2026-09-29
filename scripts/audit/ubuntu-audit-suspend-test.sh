#!/bin/bash
# 单次 suspend/resume 测试（不需要 sudo）。用法: bash ~/ubuntu-audit-suspend-test.sh [标签]
TAG=${1:-test}
LOG=~/ubuntu-audit-suspend-$TAG.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8

snap() {
  echo "--- power: AC=$(cat /sys/class/power_supply/AC/online) BAT=$(cat /sys/class/power_supply/BAT0/capacity)% charge_now=$(cat /sys/class/power_supply/BAT0/charge_now) status=$(cat /sys/class/power_supply/BAT0/status)"
  echo "--- mem_sleep: $(cat /sys/power/mem_sleep)  profile: $(powerprofilesctl get)"
  echo "--- wifi: $(nmcli -t -f DEVICE,STATE,CONNECTION dev | grep wlp)"
  ping -c2 -W2 1.1.1.1 >/dev/null 2>&1 && echo "--- net: ping OK" || echo "--- net: ping FAIL"
  echo "--- bt: $(bluetoothctl show | grep -E 'Powered|PowerState' | tr -s '\t\n' ' ')  connected: $(bluetoothctl devices Connected | tr '\n' ' ')"
  echo "--- audio sink: $(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -m1 node.description)"
  echo "--- display: $(for c in /sys/class/drm/card*-*/status; do echo -n "$(basename $(dirname $c))=$(cat $c) "; done)"
  echo "--- backlight: $(cat /sys/class/backlight/intel_backlight/brightness)/$(cat /sys/class/backlight/intel_backlight/max_brightness)"
  echo "--- usb: $(lsusb | wc -l) devices; input: $(grep -c '^N:' /proc/bus/input/devices)"
  echo "--- suspend_stats: success=$(cat /sys/power/suspend_stats/success) fail=$(cat /sys/power/suspend_stats/fail) last_hw_sleep_us=$(cat /sys/power/suspend_stats/last_hw_sleep) total_hw_sleep_us=$(cat /sys/power/suspend_stats/total_hw_sleep)"
  echo "--- s0ix residency_us: $(cat /sys/devices/system/cpu/cpuidle/low_power_idle_system_residency_us)"
}

echo "===== [$TAG] BEFORE $(date -Iseconds)"; snap
T0=$(date +%s); C0=$(cat /sys/class/power_supply/BAT0/charge_now); S0=$(cat /sys/power/suspend_stats/success)
SINCE=$(date '+%Y-%m-%d %H:%M:%S')
systemctl suspend
# 等待唤醒（success 计数器变化）
for i in $(seq 1 600); do [ "$(cat /sys/power/suspend_stats/success)" != "$S0" ] && break; [ "$(cat /sys/power/suspend_stats/fail)" != "0" ] && break; sleep 1; done
sleep 8   # 给 Wi-Fi / BT 重连时间
T1=$(date +%s); C1=$(cat /sys/class/power_supply/BAT0/charge_now)
echo "===== [$TAG] AFTER $(date -Iseconds)  wall=$((T1-T0))s  charge_delta_uAh=$((C1-C0))"; snap
echo "===== [$TAG] journal since $SINCE"
journalctl --since "$SINCE" --no-pager -o short-monotonic | grep -iE 'PM:|suspend|resume|ACPI|i915|usb|pci|bluetooth|NetworkManager.*(state|disconn)|firmware|error|fail|warn|wake' | grep -v 'Rejected send message' | head -150
