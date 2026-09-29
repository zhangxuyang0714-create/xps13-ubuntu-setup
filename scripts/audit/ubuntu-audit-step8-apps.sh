#!/bin/bash
# 应用安装（全部为官方来源；已审查各 .deb 维护脚本，均不添加软件源）
# 若 apt 会删除任何已安装软件包则停止。
LOG=~/ubuntu-audit-step8.log
exec > >(tee "$LOG") 2>&1
export LC_ALL=C.UTF-8
D=~/Downloads/installers

DEBS=("$D/WeChatLinux_x86_64.deb" "$D/LANDrop-2.7.2-linux-amd64.deb" "$D/Readest_0.12.10_amd64.deb" "$D/Sidra-1.1.2-linux-amd64.deb")
WPS=$(ls -t ~/Downloads/wps-office_*amd64.deb ~/下载/wps-office_*amd64.deb 2>/dev/null | head -1)
if [ -n "$WPS" ]; then
  echo "WPS found: $WPS"; dpkg-deb -f "$WPS" Package Version Maintainer
  DEBS+=("$WPS")
else
  echo "WPS deb 未找到，跳过（之后可单独安装）"
fi

REPO=(
  vlc apostrophe                                    # 媒体 / Markdown（Ubuntu 官方仓库）
  gnome-shell-extension-system-monitor gnome-shell-extension-prefs   # 顶栏 CPU/RAM/网络 + 扩展管理
  gir1.2-ayatanaappindicator3-0.1                                    # 坚果云托盘 (ayatana)
  nvme-cli                                          # SSD SMART 查看（无常驻服务）
)

echo "=== simulate"
SIM=$(apt-get -s install --no-install-recommends "${REPO[@]}" "${DEBS[@]}" 2>&1)
echo "$SIM" | grep -E '^(Inst|Remv|E:)'
R=$(echo "$SIM" | grep -c '^Remv'); E=$(echo "$SIM" | grep -c '^E:')
echo "removals=$R errors=$E  new_pkgs=$(echo "$SIM" | grep -c '^Inst')"
[ "$R" -ne 0 ] || [ "$E" -ne 0 ] && { echo "!!! 会删除软件包或依赖无法满足，已停止"; exit 2; }

echo "=== 备份 MIME 默认关联（WPS 安装后恢复）"
BK=~/.cache/mime-backup-before-wps; mkdir -p $BK
cp -p ~/.config/mimeapps.list $BK/user-config.list 2>/dev/null
cp -p ~/.local/share/applications/mimeapps.list $BK/user-local.list 2>/dev/null
for f in /etc/xdg/mimeapps.list /usr/share/applications/mimeapps.list; do [ -e $f ] && echo "!! $f 已存在，已备份" && sudo cp -p $f $BK/; done
echo "before: pdf=$(xdg-mime query default application/pdf) docx=$(xdg-mime query default application/vnd.openxmlformats-officedocument.wordprocessingml.document)"

echo "=== apt install"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${REPO[@]}" "${DEBS[@]}" || { echo "!!! install failed"; exit 3; }
sudo dpkg --audit; sudo apt-get check
echo "=== apt sources after install (确认没有新增源):"; ls /etc/apt/sources.list.d/

echo "=== snap"
sudo snap install telegram-desktop
sudo snap install obsidian --classic
snap list telegram-desktop obsidian

echo "=== TRIM (一次性确认，之后由 fstrim.timer 每周执行)"
sudo fstrim -av

echo "=== NVMe SMART"
sudo nvme smart-log /dev/nvme0 | grep -E 'critical_warning|temperature|available_spare|percentage_used|data_units_written|power_on_hours|unsafe_shutdowns|media_errors|num_err_log'
sudo nvme get-feature /dev/nvme0 -f 0x0c -H 2>/dev/null | head -3

if [ -n "$WPS" ]; then
  echo "=== WPS：禁用自启动与 root 定时更新（用户要求）"
  for f in /etc/cron.d/wpsupdatetask /etc/xdg/autostart/wps-office-xcupdate.desktop; do
    [ -e "$f" ] && { echo "remove $f: $(cat $f | head -2)"; sudo rm -f "$f"; }
  done
  ls /etc/xdg/autostart/ ~/.config/autostart/ 2>/dev/null | grep -i wps && echo "!! 仍有 WPS 自启动项"
  ls /etc/cron.d/ | grep -i wps && echo "!! 仍有 WPS cron"
  echo "=== 恢复 MIME 默认关联（撤销 WPS 写入的默认打开方式）"
  for f in /etc/xdg/mimeapps.list /usr/share/applications/mimeapps.list; do
    if [ -e $BK/$(basename $f) ]; then sudo cp -p $BK/$(basename $f) $f; elif [ -e $f ]; then echo "remove WPS-created $f:"; grep -i wps $f | head -5; sudo rm -f $f; fi
  done
  [ -e $BK/user-config.list ] && { diff $BK/user-config.list ~/.config/mimeapps.list; cp -p $BK/user-config.list ~/.config/mimeapps.list; }
  [ -e $BK/user-local.list ] && { diff $BK/user-local.list ~/.local/share/applications/mimeapps.list; cp -p $BK/user-local.list ~/.local/share/applications/mimeapps.list; }
  sudo chown $USER:$USER ~/.config/mimeapps.list ~/.local/share/applications/mimeapps.list 2>/dev/null
  sudo update-desktop-database -q /usr/share/applications 2>/dev/null
fi
echo "after: pdf=$(xdg-mime query default application/pdf) docx=$(xdg-mime query default application/vnd.openxmlformats-officedocument.wordprocessingml.document) xlsx=$(xdg-mime query default application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)"
echo "=== DONE $(date -Iseconds)"
