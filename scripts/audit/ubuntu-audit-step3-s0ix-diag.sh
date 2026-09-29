#!/bin/bash
# S0ix 诊断（只读）：找出阻止 s2idle 进入 SLP_S0 的设备。不修改任何设置。
LOG=~/ubuntu-audit-s0ix.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
D=/sys/kernel/debug/pmc_core
echo "=== pmc_core files"; sudo ls $D
for f in slp_s0_residency_usec pch_ip_power_gating_status ltr_show package_cstate_show substate_status_registers; do
  echo "=== $f"; sudo cat $D/$f 2>&1 | head -80
done
echo "=== pcie aspm per device"
for d in /sys/bus/pci/devices/*; do printf '%s %s runtime=%s\n' "$(basename $d)" "$(cat $d/link/l1_aspm 2>/dev/null || echo -)" "$(cat $d/power/runtime_status 2>/dev/null)"; done
sudo lspci -vv 2>/dev/null | grep -E '^[0-9a-f]{2}:|LnkCtl:.*ASPM'
echo "=== nvme apst"; sudo cat /sys/module/nvme_core/parameters/default_ps_max_latency_us
echo "=== FADT low power s0 idle"; sudo dmesg | grep -iE 'low power s0|LPS0|_DSM|s2idle' | head
echo "=== BIOS"; sudo dmidecode -s bios-version; sudo dmidecode -s bios-release-date
echo "=== DONE"
