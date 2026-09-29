# xps13-ubuntu-setup

Dell XPS 13 9365（i5-8200Y / 8 GB / JIS 键盘）上 Ubuntu 26.04 GNOME Wayland 的设置、审计记录和优化。

原则：先检查再修改；只用 Ubuntu 官方源和软件的官方发行包；不用"一键优化"工具；BIOS、固件、GRUB、内核、睡眠模式一律不动。优先级依次是：稳定 > 续航 > 睡眠可靠 > 散热 > 性能。

完整记录见 [docs/audit-report.md](docs/audit-report.md)。

## 当前状态一览

| 方面 | 设置 |
|---|---|
| 电源 | power-profiles-daemon `balanced`（`power-saver` 实测会把 CPU 压在约 500 MHz，慢 4 倍）；thermald；不装 TLP / auto-cpufreq |
| 睡眠 | `s2idle`（进不了 S0ix，但合盖待机约 0.75%/h，可以过夜）。**deep (S3) 在此机 + kernel 7.0 上唤醒会挂死，不要用** |
| 内存 | zram（内存的一半，zstd，优先级 100）+ 4 GB swap 文件兜底；systemd-oomd |
| 后台 | localsearch 只索引 XDG 目录；桌面图标扩展停用；AB Download Manager 不开机自启 |
| 输入法 | IBus：`jp` 键盘 / 智能拼音（libpinyin + 12 个官方附加词库）/ Mozc；`Super+Space` 切换 |
| 视频 | `intel-media-va-driver`（iHD），H.264 / HEVC / VP9 硬解 |
| 字体 | 日文文本优先 Noto CJK JP，中文仍是 SC |

## 目录

```
configs/etc/systemd/zram-generator.conf        zram 配置
configs/home/.config/fontconfig/conf.d/        日文优先 JP 字形
configs/home/.local/share/applications/        system-monitor 扩展 → Resources 的别名
configs/home/.config/autostart/                坚果云自启项（参考）
scripts/enable-zram.sh                         启用 zram（需 sudo）
scripts/apply-user-settings.sh                 复现用户级设置（不需 sudo，自动备份旧值）
scripts/audit/                                 审计、更新、睡眠 / S0ix 排查脚本
docs/audit-report.md                           审计报告和全部改动记录
```

## 在新装系统上复现

```bash
bash scripts/audit/ubuntu-audit-step1-update.sh    # 更新；模拟升级时发现要删包就停下
bash scripts/audit/ubuntu-audit-step2-install.sh   # 官方仓库的基础组件
bash scripts/enable-zram.sh                        # zram；装完重启一次，zstd 才会生效
bash scripts/apply-user-settings.sh                # 用户级设置
powerprofilesctl set balanced
```

`ubuntu-audit-step8-apps.sh` 需要先把各应用的官方安装包下载到 `~/Downloads/installers`。
S0ix / deep 相关的脚本（`step3`–`step6`、`step9`–`step11`、`suspend-*`）是排查用的实验脚本，不属于日常设置，运行前先看一遍脚本里的注释。

## 回滚

- zram：`sudo rm /etc/systemd/zram-generator.conf && sudo apt remove systemd-zram-generator`，然后重启
- 用户设置：`bash ~/.cache/xps13-setup-backup/<时间>/restore-gsettings.sh`
- 桌面图标：`gnome-extensions enable ding@rastersoft.com`

## 未上传的内容

原始基线快照和过程日志里有序列号、MAC 地址、硬件 ID 之类的信息，所以不放进公开仓库。git、SSH 配置也不放。
