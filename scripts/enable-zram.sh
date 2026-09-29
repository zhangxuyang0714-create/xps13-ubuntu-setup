#!/bin/bash
# 启用 zram（Ubuntu 官方包 systemd-zram-generator）
# 回滚：sudo rm /etc/systemd/zram-generator.conf && sudo apt remove systemd-zram-generator && 重启
set -euo pipefail
LOG=~/enable-zram-$(date +%Y%m%d-%H%M%S).log
exec > >(tee "$LOG") 2>&1

echo "== 之前 =="; swapon --show; free -h

if [ -e /etc/systemd/zram-generator.conf ]; then
  echo "已存在 /etc/systemd/zram-generator.conf，不覆盖，退出。"; exit 1
fi

sudo apt-get install -y systemd-zram-generator

sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

echo "== 之后 =="; swapon --show; zramctl; free -h
echo "日志：$LOG"
