#!/bin/bash
# Step 2: 仅从 Ubuntu 官方仓库安装基础组件（不含任何 GUI 应用软件）
# 同样：若会删除任何软件包，则停止。
LOG=~/ubuntu-audit-step2.log
exec > >(tee "$LOG") 2>&1
set -u
export LC_ALL=C.UTF-8

PKGS=(
  # [3/4] 日文输入法 Mozc + 词典工具 / 日英 locale
  ibus-mozc mozc-utils-gui language-pack-ja language-pack-gnome-ja language-pack-en
  # [5] Intel 硬件视频解码 (Kaby Lake, iHD) + 诊断工具
  intel-media-va-driver vainfo libinput-tools v4l-utils lm-sensors
  # [8/9] 开发基础
  git build-essential pkg-config cmake ninja-build python3-pip python3-venv
)

echo "=== simulate install"
SIM=$(apt-get -s install --no-install-recommends "${PKGS[@]}")
echo "$SIM" | grep -E '^(Inst|Remv)'
REMOVALS=$(echo "$SIM" | grep -c '^Remv')
echo "removals=$REMOVALS"
[ "$REMOVALS" -ne 0 ] && { echo "!!! 会删除软件包，已停止"; exit 2; }

echo "=== install"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${PKGS[@]}" || { echo "!!! install failed"; exit 3; }

echo "=== post-check"
sudo dpkg --audit
sudo apt-get check
locale -a
echo "=== DONE $(date -Iseconds)"
