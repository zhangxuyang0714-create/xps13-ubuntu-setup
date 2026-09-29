#!/bin/bash
# 复现本机的用户级设置（不需要 sudo）。改之前会把旧值备份到 ~/.cache/xps13-setup-backup/。
# 只改 gsettings 和 ~ 下的配置文件，不装软件、不动系统配置。
set -eu
cd "$(dirname "$0")/.."
BK=~/.cache/xps13-setup-backup/$(date +%Y%m%d-%H%M%S); mkdir -p "$BK"

KEYS=(
  "org.gnome.desktop.input-sources sources [('xkb','jp'),('ibus','libpinyin'),('ibus','mozc-on')]"
  "org.gnome.desktop.peripherals.touchpad tap-to-click true"
  "org.gnome.desktop.peripherals.touchpad natural-scroll true"
  "org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true"
  "org.gnome.desktop.peripherals.touchpad disable-while-typing true"
  "org.gnome.shell.extensions.dash-to-dock always-center-icons true"
  "org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900"
  "org.freedesktop.Tracker3.Miner.Files index-recursive-directories ['&DOCUMENTS','&DOWNLOAD','&PICTURES','&MUSIC','&VIDEOS','&DESKTOP']"
  "org.freedesktop.Tracker3.Miner.Files index-single-directories ['\$HOME']"
  "com.github.libpinyin.ibus-libpinyin.libpinyin dictionaries '4;5;6;7;8;9;10;11;12;13;14;15'"
  "com.github.libpinyin.ibus-libpinyin.libpinyin init-chinese true"
  "com.github.libpinyin.ibus-libpinyin.libpinyin init-full-punct true"
)

for k in "${KEYS[@]}"; do
  read -r schema key value <<<"$k"
  if ! gsettings list-keys "$schema" >/dev/null 2>&1; then echo "跳过（schema 不存在）：$schema"; continue; fi
  echo "gsettings set $schema $key \"$(gsettings get "$schema" "$key")\"" >> "$BK/restore-gsettings.sh"
  gsettings set "$schema" "$key" "$value"
  echo "✅ $schema $key = $value"
done

# 停用桌面图标扩展（约 100 MB）；恢复：gnome-extensions enable ding@rastersoft.com
gnome-extensions disable ding@rastersoft.com 2>/dev/null && echo "✅ 已停用 ding" || true

# 用户级配置文件：已存在的先备份
for f in .config/fontconfig/conf.d/60-ja-prefer-noto-jp.conf .local/share/applications/org.gnome.SystemMonitor.desktop; do
  if [ -e ~/"$f" ]; then mkdir -p "$BK/$(dirname "$f")"; cp -p ~/"$f" "$BK/$f"; fi
  mkdir -p ~/"$(dirname "$f")"; cp "configs/home/$f" ~/"$f"; echo "✅ ~/$f"
done

echo "旧值备份在 $BK（恢复 gsettings：bash $BK/restore-gsettings.sh）"
