# Ubuntu 初始化审计报告 — Dell XPS 13 9365

- 审计日期：2026-09-26（JST）
- 原始基线快照和过程日志含设备标识信息，**未上传**本仓库。
- 脚本：见本仓库 `scripts/audit/`（在机器上原位于 `~/`，日志写到 `~/ubuntu-audit-*.log`）

图例：✅ 正常　⚠️ 已知问题 / 可以使用　🔧 已修复　❌ 需要进一步处理

---

## 系统状态

| 项目 | 值 | 状态 |
|---|---|---|
| 机型 | Dell XPS 13 9365（2-in-1，触摸屏 + Wacom 笔） | ✅ |
| BIOS | 2.24.0（2022-08-16），fwupd/LVFS 显示无可用更新 | ✅ 未改动 |
| OS | Ubuntu 26.04.1 LTS (resolute) | ✅ |
| Kernel（运行中） | 7.0.0-34-generic（HWE meta：linux-image-generic-hwe-26.04） | ✅ |
| Kernel（保留回退） | 7.0.0-30-generic（`/boot` 中完整存在，可从 GRUB 选择） | ✅ 未删除 |
| CPU | Intel Core i5-8200Y（Amber Lake-Y，2C/4T），microcode 0xf6 | ✅ |
| RAM | 7.1 GiB，swap 4 GiB（`/swap.img`） | ✅ |
| SSD | SK hynix PC401 256 GB NVMe，ext4 根分区 + 1 GB ESP | ✅ |
| 会话 | GNOME / **Wayland** | ✅ |
| systemd | 259.5，无 failed unit（system / user 均为 0） | ✅ |
| Secure Boot | **Disabled**（只记录，未改动） | ⚠️ 见问题 7 |
| Locale | `zh_CN.UTF-8`；已新增 `ja_JP.UTF-8`、`en_US.UTF-8` 等 | 🔧 |
| DKMS | 未安装、无第三方内核模块 | ✅ |

## 软件源状态

| 源 | 结论 |
|---|---|
| `ubuntu.sources`：`jp.archive.ubuntu.com` resolute / -updates / -backports，main restricted universe multiverse | ✅ 官方日本镜像，与版本匹配 |
| `ubuntu.sources`：`security.ubuntu.com` resolute-security | ✅ |
| `google-chrome.sources`（dl.google.com，有 Signed-By keyring） | ✅ 官方第三方源，有效，保留 |
| `ubuntu.sources.curtin.orig` | ✅ 安装程序留下的备份，扩展名不被 apt 读取，无影响，未删除 |
| `/etc/apt/sources.list` | 空（deb822 格式已迁移） ✅ |
| PPA | 无 ✅ |

未添加任何新源。

## 更新状态

- 🔧 `apt-get update` + `full-upgrade`：**43 个包升级，0 个删除**，kernel 未变（bluez、pipewire、mutter、thermald、netplan 等）。
- ✅ `dpkg --audit` 干净；无 held 包；`apt-get check` 无 unmet dependencies；无 dpkg 中断状态。
- ⚠️ 9 个包因 Ubuntu **phased updates** 被暂缓（ubuntu-desktop meta、release-upgrader 等）。这是 Ubuntu 的正常分批推送机制，会自动到来，**不需要强制安装**。
- ⚠️ apt 提示 7.0.0-30 相关包可 `autoremove`。**按要求未执行**，保留为回退内核。
- ✅ 更新后无需重启（无 `/var/run/reboot-required`）。

## 输入法状态

- 框架：**IBus 1.5.34**（GNOME Wayland 原生集成，本来就在运行，环境变量已指向 ibus）。
- ⚠️ 系统同时装有 **fcitx5 全套**（含 chinese-addons），但**未运行、无自启动、不是默认框架**，与 IBus 不冲突。按“不删除”原则保留，将来如果不打算用 fcitx5，可以考虑卸载。
- 🔧 输入源（`Super+Space` 前进，`Shift+Super+Space` 后退）：
  1. `English (Japanese)`：xkb `jp`（与实体 JIS 键盘一致），用于终端、快捷键和开发工具
  2. `智能拼音 (ibus-libpinyin 1.16.5)`：简体、初始中文模式、中文全角标点
  3. `Mozc:あ (ibus-mozc 2.29.5160.102)`：切入即为平假名；`F7` 片假名，空格转换汉字，`半角/全角` 切直接输入
- ✅ 用户实测：`你好世界` / `こんにちは世界` / `Hello World`，以及中 → 日 → 英 → 中切换全部正常。
- ✅ 拼音**云输入保持关闭**（默认值），避免输入内容外发。

## 中文词库状态

| 项目 | 值 |
|---|---|
| 引擎 / 数据 | ibus-libpinyin 1.16.5 + **libpinyin-data 2.10.3**（Ubuntu 官方包） |
| 格式版本 | binary format 7 / model data 14，用户库 `~/.cache/ibus/libpinyin/user.conf` 与系统库**一致** |
| 完整性 | `dpkg --verify libpinyin-data libpinyin15 ibus-libpinyin` 通过 ✅ |
| 🔧 启用 | libpinyin 自带的 12 个官方分类附加词库（艺术、文化、经济、地理、历史、生活、自然、人物、科学、社会、体育、科技，共约 0.6 MB） |

选择理由：这些是 libpinyin 上游随包提供、与引擎版本严格匹配的词库，资源占用极小，不需要下载外部文件。**没有**引入第三方大词库（例如搜狗细胞词库转换）：来源和格式兼容性不可控，也会明显增加内存占用。

## 日文词库状态

| 项目 | 值 |
|---|---|
| 引擎 / 数据 | Mozc 2.29.5160.102（`mozc-server` 内置系统词典，Ubuntu 官方包） |
| 完整性 | `dpkg --verify mozc-server mozc-data ibus-mozc` 通过 ✅ |
| 词典工具 | 🔧 `mozc-utils-gui`（设置 / 用户词典管理，可从 Mozc 菜单打开） |

选择理由：在 Linux 上可用的日文引擎里（Mozc / Anthy / KKC），Mozc 转换质量最好，而且是 Ubuntu 日文环境的默认推荐（`check-language-support -l ja` 给出的也是它）。它的系统词典内置在 server 里，随 apt 更新，不需要另外下载。**没有**添加 mozc-ut 等第三方扩展词典（非官方打包，体积大）。

## 驱动状态

| 组件 | 驱动 / 固件 | 状态 |
|---|---|---|
| GPU | i915，DMC `kbl_dmc_ver1_04.bin` 已加载 | ✅ |
| VA-API | 🔧 **原本缺失**，已安装 `intel-media-va-driver`（iHD 26.1.2）：H.264 / HEVC / HEVC10 / VP8 / VP9 / JPEG 硬件解码可用 | 🔧 |
| Microcode | intel-microcode 3.20260210，运行 0xf6 | ✅ |
| Wi-Fi | iwlwifi / iwlmvm，fw 36.c8e8e144.0 | ✅ |
| BT | btusb / btintel | ✅（见下） |
| Audio | snd_hda_intel（ALC3271）+ HDMI/DP；SOF 固件已安装但此机型走 HDA | ✅ |
| 读卡器 | rtsx_pci（RTS525A） | ✅ |
| 传感器 | dell_smm_hwmon、coretemp、nvme、iwlwifi、acpitz | ✅ |
| Thermal | thermald 运行中，proc_thermal / intel_pch_thermal | ✅ |
| 缺失固件 | 本次开机无 `Direct firmware load ... failed` | ✅ |
| 指纹 | Validity VFS7552 `138a:0091`：Linux 下无 libfprint 驱动 | ⚠️ 不可用（硬件限制） |

## Wi-Fi / Bluetooth

- ✅ Wi-Fi：Intel Wireless 8265，2.4 GHz 和 5 GHz 都支持（NM 确认），当前连在 2.4 GHz ch1，信号 79。本次开机无意外断线记录；两次睡眠唤醒后约 4 秒内自动重连，ping 通过。
- ⚠️ 管控域显示 `country 00`（self-managed）：iwlwifi 的 LAR 会根据周围 AP 自动判断，通常不影响使用；如果日后 5 GHz 部分信道（DFS）连不上，可以再排查。
- ✅ Bluetooth：Intel 8265 BT（`8087:0a2b`），BlueZ 5.85（已更新），控制器 Powered。Logitech Pebble 在**电池合盖睡眠后自动重连**。
- ⚠️ 开机时有 `hci0: Reading supported features failed (-16)`：Intel 老款 BT 固件的已知无害提示，功能正常。

## Audio

- ✅ PipeWire 1.6.2 + WirePlumber，默认 sink/source 为内置模拟立体声，睡眠唤醒后保持不变。
- ⚠️ 扬声器和麦克风的**实际发声 / 收音**没有单独做听感测试。设备枚举和路由都正常；如有需要，可在“设置 → 声音”里做一次“测试”。

## GPU / Display

- ✅ 内置 eDP 已连接；背光 `intel_backlight` 7500/7500 可调；睡眠唤醒后显示和背光正常。
- ⚠️ 唤醒后出现过一次 `i915 ... Atomic update failure on pipe A`：单次、无可见影响，属于 i915 已知的偶发时序警告；只有频繁出现或伴随闪烁时才需要处理。
- ⚠️ 外接显示：两个 USB-C（Thunderbolt 3 / DP Alt Mode）口**没有外接设备，未实测**。控制器（Alpine Ridge）在 bolt 强制上电时能正常枚举。

## Touchpad / Keyboard

- ✅ 触摸板 Synaptics `06CB:76AF`（I2C-HID，libinput）：tap-to-click、双指滚动、natural scroll、打字时禁用都已开启；睡眠唤醒后可用（用户实测）。
- ✅ 触摸屏 / 笔：Wacom HID 482E 已识别。
- ✅ 键盘：AT Translated Set 2（JIS），布局 `jp`。
- ⚠️ `psmouse serio1: Failed to enable mouse`：这是固件模拟出的 PS/2 鼠标（实际触摸板走 I2C），报错无害。

## Camera

- ✅ Realtek Integrated Webcam HD `0bda:58c8`（uvcvideo），V4L2 格式为 MJPG 1280×720@30 / YUYV 640×480@30，PipeWire 可见。

## Battery

| 项目 | 值 |
|---|---|
| 型号 | DELL NP0V38B（LGC） |
| 设计容量 / 当前满电 | 45.99 Wh / 39.24 Wh → **健康度约 85.3%** |
| 循环计数 | 固件报告 0（这款电池不提供循环计数，不可信） |
| 充电 | USB-C PD 适配器，AC 识别正常 |
| 电源管理 | power-profiles-daemon（当前 balanced），intel_pstate / powersave + EPP；thermald |
| TLP / tuned / auto-cpufreq | **均未安装** → 无冲突 ✅ |
| 运行功耗（亮度 100%，空闲） | 约 8.5 W |

- ✅ GNOME：低电量时自动切到 power-saver；电池模式下 15 分钟无操作自动睡眠；合盖睡眠（AC 和电池都是）。

## Suspend / Resume

| 项目 | 结果 |
|---|---|
| 支持模式 | `mem_sleep: [s2idle] deep`（当前 s2idle，**未修改**） |
| Hibernate | 内核支持，但 Ubuntu 默认未启用；swap 4 GB < RAM 7.1 GB；**未启用、未修改** |
| AC 测试 | ✅ 睡眠 5 分 8 秒，按键唤醒；Wi-Fi、网络、声音、显示、USB 都正常 |
| 电池合盖测试 | ✅ 睡眠 16 分 35 秒，开盖唤醒；Wi-Fi、BT 鼠标、声音、显示、USB 都正常 |
| suspend_stats | success 3 / fail 0 |
| **S0ix 驻留** | ❌ **`last_hw_sleep = 0`、`low_power_idle_system_residency_us = 0`**（intel_pmc_core 已加载） |
| **睡眠耗电** | 电池测试：16.6 分钟掉 29 mAh，约 **0.9 W，约每小时 2.3%** |
| S0ix 诊断 | CPU 能进 PC10；BIOS 的 LPS0（`\_SB_.PEPD`）entry/exit 成功；`ltr_ignore_all_suspend=Y`；内核报告 **`CPU did not enter SLP_S0!!! (S0ix cnt=0)`** → PCH 某个 IP 没有断电。醒着时 SPC（PCIe 端口 9～12：读卡器 + Wi-Fi）一直 On，读卡器链路 ASPM Disabled |
| 读卡器实验 | 在 sysfs 里临时移除 RTS525A 后仍然是 0。但芯片仍通电、链路仍在（唤醒时 pciehp 又重新枚举了它）→ **无法下结论**，只有在 BIOS 里关闭才能真正验证 |
| **deep (S3) 实验** | ❌ **唤醒挂死**：`PM: suspend entry (deep)` 之后没有任何日志，只能强制断电。fsck 自动修复了 ext4 日志和 ESP dirty 标记，数据无损。**deep 在此机 + kernel 7.0 下不可用** |

## Wake Sources

当前允许唤醒系统的设备：

| 设备 | 说明 | 评价 |
|---|---|---|
| LID0 / PBTN / 电源、睡眠按钮 / intel-hid / intel-vbtn | 合盖开盖、电源键 | ✅ 必要 |
| serio0（atkbd） | 内置键盘 | ✅ 合理（AC 测试就是按键唤醒，IRQ 1） |
| XHC（00:14.0，USB） | **包括蓝牙控制器**（BT 挂在 USB 上），BT 鼠标点击可以唤醒 | ⚠️ 见问题 3 |
| i2c-DLL077A:01 | 触摸板 | ⚠️ 见问题 3 |
| RP05 / RP10（PCIe root port，后者接 Wi-Fi） | 平台默认 | ✅ 未观察到异常唤醒 |
| rtc_cmos / alarmtimer | 定时唤醒 | ✅ 必要 |

两次有效测试都**没有异常唤醒**。第一次测试的“1 秒即醒”是误触所致（触摸板或鼠标），这也证明了上述唤醒源确实有效。**没有关闭任何唤醒源。**

## 缺失依赖

### A. 真正缺失且应该安装（🔧 已安装，全部来自 Ubuntu 官方仓库）
- `intel-media-va-driver`：没有它就无法硬件解码视频，直接影响续航
- `ibus-mozc`、`mozc-utils-gui`：三语输入的日文部分
- `language-pack-ja`、`language-pack-gnome-ja`、`language-pack-en`：ja_JP / en_US locale 与日文翻译
- `git`：开发必需

### B. 当前系统正常，不需要安装
- systemd、udev、dbus、polkit：正常；`ldconfig` 缓存 1212 条
- 扫描 `/usr/bin` 与系统 `.so`，**没有 `not found` 的共享库**
- 没有 broken package、没有 unmet dependency、dpkg 状态干净
- openssh-client 10.2p1、curl 8.18、wget 1.25、unzip 已安装
- 没有缺失的固件

### C. 可选组件（未安装）
- `dkms`：目前没有第三方内核模块，不需要
- `tlp` / `auto-cpufreq`：会与 power-profiles-daemon 冲突，**不建议安装**
- `libfprint` 指纹：硬件不受支持
- `intel-media-va-driver-non-free`：只多了部分编码功能，解码不需要

### D. 开发环境需要（🔧 已安装）
- `build-essential`（gcc/g++ 15.2、make 4.4.1）、`pkg-config`、`cmake` 4.2.3、`ninja-build` 1.13.2、`python3-pip` 25.1.1、`python3-venv`（Python 3.14.4）
- 诊断工具：`vainfo`、`libinput-tools`、`v4l-utils`、`lm-sensors`
- Node.js / npm：**未安装**（原本也没有）。按要求不主动安装，需要时再定版本和安装方式

### E. 第三方软件需要
- Google Chrome：已经通过官方源安装，源有效
- 其他 GUI 软件（GIMP、VLC、WPS、PeaZip、Cider 等）：**按要求暂不安装**

## 开发环境

| 项目 | 状态 |
|---|---|
| git 2.53.0 | 🔧 已安装 |
| git `user.name` / `user.email` | ❌ **未设置**（`~/.gitconfig` 不存在） |
| SSH key | ❌ **不存在**（`~/.ssh` 里只有空的 authorized_keys）。按要求只报告，未生成 |
| ssh-agent | ✅ `gcr-ssh-agent`（SSH_AUTH_SOCK=/run/user/1000/gcr/ssh）运行中，当前没有 key |
| GitHub HTTPS | ✅ `https://github.com` 200，0.76 s |
| GitHub SSH | ✅ 22 端口和 ssh.github.com:443 都能连通；认证返回 `Permission denied (publickey)`，**原因是还没有 key，属于预期** |

---

## 发现的问题

### 1. ❌ s2idle 睡眠进入不了 S0ix（睡眠耗电偏高）
- **问题**：合盖睡眠时，平台没有进入 SLP_S0 深度低功耗，S0ix 驻留一直为 0。
- **原因**：待定位。常见原因是某个 PCH IP 或 PCIe 设备没有进入低功耗（Wi-Fi、NVMe APST、读卡器、ISH、xHCI、ME 等）。另外，XPS 13 9365 这一代 Kaby Lake/Amber Lake-Y 的固件原本主要为 S3（deep）设计。
- **当前影响**：合盖睡眠约每小时掉 **2.3%**（0.9 W）。满电合盖大约 **1.5～2 天**耗尽；日常带出门、当天再充电没有问题，但**不适合合盖放好几天**。正常的 S0ix / S3 通常能做到每小时 0.3～0.7%。
- **是否已修复**：否。已做的诊断：只读 pmc_core 诊断 → 睡眠期间调试日志（确认没进 SLP_S0）→ sysfs 移除读卡器（无法下结论）→ 临时 deep 测试（**唤醒挂死，排除**）。
- **下一步建议**（任选，都要你决定）：
  1. **维持 s2idle**（当前状态，唤醒 4/4 成功）。长时间不用时关机。
  2. 在 BIOS 里关闭 SD Card Reader（你基本不用 SD 卡），然后重新运行 `~/ubuntu-audit-step4-s0ix-trace.sh` 验证能否进入 SLP_S0。**BIOS 设置需要你亲自操作。**
  3. 远期可以考虑 suspend-then-hibernate（睡眠 N 小时后自动休眠）。但要先把 swap 扩到 ≥ 8 GB，并在 GRUB 里加 `resume=` 参数，属于高风险改动，需要单独评估。

### 2. ⚠️ ACPI `_Q66` PATM mutex 错误
- **问题**：开机和部分 EC 事件（包括唤醒、插拔电源）时，内核报 `ACPI Error ... ECDV._Q66 AE_AML_NOT_OWNER`。
- **原因**：Dell BIOS 里 EC 查询方法的 AML 缺陷（固件 bug，与 Linux 驱动无关）。
- **当前影响**：没有观察到功能影响；电池、背光和合盖事件都正常。
- **是否已修复**：否，也不需要。只能等 BIOS 更新，而 fwupd 显示 2.24.0 已经是最新。
- **下一步建议**：观察即可。

### 3. ⚠️ USB（含蓝牙）与触摸板可以唤醒系统
- **问题**：误触触摸板，或者点击蓝牙鼠标，可能让睡眠中的电脑醒来。
- **原因**：XHC（蓝牙挂在 USB 上）和 I2C 触摸板默认 wakeup=enabled。
- **当前影响**：合盖时触摸板被盖住，一般不会误触；但放进包里时，蓝牙鼠标如果开着、被碰到，有可能唤醒电脑。
- **是否已修复**：否，按规则不直接关闭唤醒源。
- **下一步建议**：出门前关掉鼠标开关即可。如果以后在 journal 里看到异常唤醒，再用 udev 规则针对单个设备关闭。

### 4. ⚠️ 电池健康度约 85%
- **问题**：满电 39.2 Wh / 设计 46.0 Wh。
- **原因**：锂电池正常老化（2017 年左右的机型）。
- **当前影响**：续航比新机少约 15%。空闲、亮度 100% 时功耗约 8.5 W；调低亮度能显著省电。
- **是否已修复**：不适用。
- **下一步建议**：可以在 BIOS 里把 Dell 电池充电策略设为 Adaptive 或 Primarily AC，减缓老化（**BIOS 设置需要你自己决定**）。

### 5. ❌ Git 身份和 SSH key 未配置
- **问题**：没有 `user.name`、`user.email`，也没有 SSH key。
- **原因**：新装系统。
- **当前影响**：无法以你的身份提交代码，也无法通过 SSH 推送到 GitHub。
- **是否已修复**：否，按要求先报告。
- **下一步建议**：告诉我要用的 name / email，然后生成 `ed25519` key（不会覆盖任何已有文件，因为目前没有），再把公钥添加到 GitHub。

### 6. ⚠️ fcitx5 与 IBus 同时安装
- **问题**：装了两个输入法框架。
- **原因**：安装时带进来的，或者之前手动装的。
- **当前影响**：无。fcitx5 不运行、不自启动。
- **是否已修复**：不需要。
- **下一步建议**：确定只用 IBus 后，可以卸载 fcitx5 系列包，腾出一点空间（非必需）。

### 7. ⚠️ Secure Boot 关闭；旧内核 7.0.0-30 是 unsigned 镜像
- **问题**：SB 处于关闭状态；回退内核的包名是 `linux-image-unsigned-7.0.0-30-generic`。
- **当前影响**：SB 关闭时两个内核都能启动，回退路径可用。如果以后**开启** SB，7.0.0-30 将无法作为回退内核启动。
- **是否已修复**：不改动（涉及安全机制和 BIOS）。
- **下一步建议**：维持现状；如果要开启 SB，先确认有一个签名的回退内核。

### 8. ⚠️ deep (S3) 唤醒挂死，以及随后的 TPM 初始化失败
- **问题**：临时切到 deep 测试时，唤醒阶段整机挂死，只能强制断电。重启后 `tpm_tis MSFT0101:00: probe failed with error -1`，`/dev/tpm0` 不存在（上次开机时正常）。
- **原因**：S3 resume 在固件或早期内核阶段挂住（没有任何日志）。强制断电后，Intel PTT（ME 里的固件 TPM）状态卡住。
- **当前影响**：deep 不可用（已自动恢复 s2idle，没有持久改动）。TPM 暂时不可用；系统盘没有用 TPM 加密，不影响开机和日常使用。
- **是否已修复**：mem_sleep 已恢复 s2idle ✅；文件系统已自动修复 ✅；TPM 待处理。
- **下一步建议**：**完整关机**（不是重启），等 10 秒再开机，确认 `/dev/tpm0` 恢复。**永远不要**通过 GRUB 把默认睡眠改成 deep。

### 9. ⚠️ 未实测的项目
- 外接显示（USB-C / DP）、USB 存储、扬声器与麦克风的听感、Wi-Fi 5 GHz 实际连接：条件所限没有实测，驱动和枚举层面都正常。

---

## 当前是否适合日常携带使用

**适合当天往返的日常携带**：系统更新完成，软件包状态干净；三语输入实测正常；Wi-Fi、蓝牙、声音、显示、触摸板、摄像头都正常；AC 和电池两种场景下的睡眠唤醒都成功，唤醒后外设自动恢复；电源管理只有 power-profiles-daemon 一套，没有冲突。

**有一个会影响便携性的限制**：睡眠时进不了 S0ix，合盖每小时掉电约 2.3%，**不适合合盖存放多天**（问题 1）。deep (S3) 已实测会挂死，不能作为替代方案（问题 8）。在解决之前，**当天用的合盖睡眠没问题，隔夜或更长时间不用建议关机**。

---

# 第二阶段：应用安装与桌面调整（2026-09-26）

## 更新收尾
- 🔧 apt phased updates 9 个（强制包含 phased），0 删除；snap 7 个全部刷新。apt / snap 均无剩余更新。

## 已安装应用（均为官方来源；已审查 .deb 维护脚本，**未新增任何软件源**）
| 应用 | 来源 / 版本 | 方式 |
|---|---|---|
| 微信 | Tencent 官方 deb 4.1.13.23 | apt 本地包（**不自动更新**，需手动下载新版） |
| WPS Office | linux.wps.cn 12.1.2.28080 | apt 本地包；🔧 已撤销其写入的 ~100 条默认打开方式（系统级 + 用户级）；无 cron / 自启动 / 服务 |
| Telegram | snap `telegram-desktop` 7.2.9（Telegram FZ-LLC，已验证） | snap 自动更新 |
| Obsidian | snap `obsidian` 1.13.7（obsidianmd，classic） | snap 自动更新 |
| 坚果云 6.4.3 | 官方 dist 包 → `~/.nutstore/dist`（官方 .deb 依赖 libnautilus-extension1a，26.04 不可装） | 用户目录；自启动；托盘走 AyatanaAppIndicator；**未执行**其修改 /etc/sysctl.conf 的 inotify 脚本 |
| LANDrop 2.7.2 | releases.landrop.app 官方 deb（⚠️ 闭源，桌面版 2024-10 后未更新） | apt 本地包 |
| AB Download Manager 1.10.4 | GitHub 官方 tar.gz（MD5 校验通过）→ `~/.local/ABDownloadManager` | 用户目录；⚠️ 已自行添加开机自启 |
| Readest 0.12.10 | GitHub 官方 deb | apt 本地包 |
| Sidra 1.1.2（Apple Music） | GitHub 官方 deb；附带 AppArmor 配置 `/etc/apparmor.d/sidra` | apt 本地包 |
| VLC 3.0.23 / Apostrophe 3.4 | Ubuntu 官方仓库 | apt |
| PDF | 系统自带 Papers（保持默认） | — |

默认打开方式（已验证）：PDF → Papers；docx → LibreOffice Writer；xlsx → LibreOffice Calc。

## 字体
- 🔧 366 个微软 TTF/TTC → `~/.local/share/fonts/microsoft/`（640 MB，用户级；跳过 10 个 .fon）。系统默认字体回退未改变。
- 🔧 `~/.config/fontconfig/conf.d/60-ja-prefer-noto-jp.conf`：lang=ja 优先 Noto CJK JP（中文仍 SC）。

## 桌面
- 🔧 Ubuntu Dock：`always-center-icons=true`（底栏全宽，图标居中；未装扩展）。
- 🔧 顶栏 CPU/RAM/网络：GNOME 官方 `system-monitor` 扩展 50.0（apt），已加入 enabled-extensions，**重新登录后生效**。无温度显示。

## 电源 / 性能审计
| 组件 | 结论 |
|---|---|
| power-profiles-daemon | ✅ 唯一调频管理者；🔧 profile 从 performance 改回 **balanced** |
| TLP / auto-cpufreq / tuned | ✅ 未安装，不需要（会冲突） |
| thermald | ✅ 运行中 |
| fwupd | ✅ 仅检查，无可用更新 |
| irqbalance | ✅ 未安装，不需要（4 线程笔记本，中断已分散） |
| systemd-oomd | ✅ 运行并监控用户会话 |
| zram / zswap | ✅ 未启用；swap 使用 0、内存压力 0 → 暂不需要 |
| CPU | intel_pstate active + powersave governor + EPP；400–3900 MHz 未锁频；C1–C10 全开，C10 占主导 |
| GPU | i915 RC6 已启用，空闲 300 MHz；VA-API (iHD) 已装 |
| SSD | 🔧 手动 fstrim 一次（/ 209.8 GiB、/boot/efi 1 GiB）；fstrim.timer 每周；APST 已启用 |
| NVMe SMART | critical_warning 0、available_spare 100%、**percentage_used 0%**、media_errors 0、通电 1128 h、unsafe_shutdowns 184（历史累计，含今天 S3 挂死 1 次） |

## 重启后复核（2026-09-26 19:00）
- 🔧 TPM 恢复：`tpm_tis: 2.0 TPM (device-id 0xFE)`，`/dev/tpm0`、`/dev/tpmrm0` 存在（问题 8 的 TPM 部分已解决）。
- 🔧 顶栏 system-monitor 扩展：ACTIVE。
- ✅ 正常关机（journal 正常停止）；无 failed unit；无新错误；power profile 保持 balanced；mem_sleep 保持 s2idle。
- 🔧 顶栏监控实际显示：官方 system-monitor 扩展仅在存在 `org.gnome.SystemMonitor.desktop` 时显示指示器，而 26.04 默认监视器是 Resources。已添加用户级别名 `~/.local/share/applications/org.gnome.SystemMonitor.desktop`（NoDisplay，指向 `resources`），未安装额外软件；用户确认顶栏已显示。

## S0ix 排查结论（2026-09-26 19:00–19:32，暂停，用户先使用观察）
| 实验 | 结果 |
|---|---|
| 飞行模式（Wi-Fi + BT rfkill） | 睡 ~6 min，SLP_S0=0 → 无线排除 |
| ISH / 1d.0 / 1c.0 runtime PM=auto | 设备仍 runtime active；PCH IP XHCI、SPC、ISH 仍 On；SLP_S0=0 → runtime PM / powertop auto-tune 无效 |
| 解绑 ISH 驱动 | ISH IP 仍 On（无驱动则无人令其进入低功耗）→ 无法下结论；已重新绑定，7 个传感器恢复 |
| sysfs 移除读卡器（此前） | 芯片仍通电 → 无法下结论 |

- 当前状态：全部实验均为临时性，已恢复；s2idle 唤醒稳定。
- 剩余唯一低风险验证：BIOS 关闭 SD 读卡器后运行 `~/ubuntu-audit-step4-s0ix-trace.sh`（需用户在 BIOS 操作）。
- 若无效：接受现状（当天合盖、隔夜关机），或另行评估 suspend-then-hibernate（swap ≥ 8 GB + GRUB `resume=`，需批准）。
- **不建议**：deep (S3)（实测挂死）、powertop --auto-tune（实测打不到阻塞点）。

## GitHub（2026-09-26）
- 🔧 git：配置了用户名与 GitHub noreply 邮箱；init.defaultBranch=main
- 🔧 SSH：生成 ed25519 key，`~/.ssh/config` 仅对 github.com 指定该 key；github.com 主机指纹已与 api.github.com/meta 核对
- 🔧 gh（Ubuntu 仓库）登录，token 存于 GNOME keyring，git protocol=ssh；账户中旧 key 已清理
- ✅ `ssh -T git@github.com` 认证通过

## 实际使用功耗复测（2026-09-26 23:10，电池）
- **合盖待机（长时样本）**：19:47:36 → 22:48:44 睡眠 **3 h 01 min**，UPower 电量 83% → 81%（按跳变时刻修正后约掉 2.2–2.3%）→ **约 0.75%/h ≈ 0.3 W**。S0ix 驻留仍为 0。
  - 早前 16 分钟测试得出的 0.9 W / 2.3%/h 被短时样本、睡眠进出过程和电量计粒度放大，**以本次 3 小时结果为准**。
  - 推算：从 80%（充电上限）合盖约可待机 4 天以上；一夜 8 h 约掉 6%。
- **亮屏使用**：FHD、亮度 30%、power-saver，Chrome 多标签 + 终端 → **4.5–4.7 W**（波动 3.4–10 W），UPower 预估剩余 6.7 h。主要占用：Chrome 多个进程、gnome-shell（合成）、终端输出。

## 一夜待机实测（2026-09-26 23:25 → 2026-09-27 12:28，电池）
- 睡眠 **13 h 03 min**（s2idle，合盖/开盖；唤醒源 IRQ 9 = 开盖；suspend_stats 成功 5 / 失败 0）
- 电量：睡前约 73.8%（23:21:59 跳到 74% 后亮屏 3.4 min）→ 醒后约 63.5% ⇒ **约 10.3%，≈ 0.79%/h ≈ 0.31 W**，与 3 h 样本（0.75%/h）一致
- 唤醒后 Wi-Fi 已连接、BT 在线、无新错误
- 结论：✅ 当前 s2idle 待机表现稳定，一夜约 10%，可合盖过夜；S0ix 仍未进入（last_hw_sleep=0），进一步优化空间约 0.2 W，非必要

## CPU 占用优化（2026-09-27）
- 现象：打开软件 / 工作时 CPU 直接 100%。
- 🔍 原因 1（主要）：电源模式被手动设为 **power-saver**（电量 53%，非低电量自动切换）→ EPP=power，CPU 被压在 ~500 MHz。实测同一 SHA-256 任务：power-saver **4.6–5.2 s**，balanced **1.26 s**（慢约 4 倍）。
- 🔍 原因 2：开机后头几分钟的集中负载（前 4 分钟 CPU 时间）：gnome-shell 50 s、**AB Download Manager 45 s**、Chrome ~60 s、坚果云 24 s、ibus-extension 23 s；之后空闲均 ≈0。
- ✅ 已排除：无温度降频（40 °C，throttle 计数 0）；RAPL PL1 7 W / PL2 18 W 为 Dell 正常值；Chrome GPU 加速正常（Wayland，GPU 进程无崩溃）。
- 🔧 电源模式改回 **balanced**（电池下 EPP=balance_power；≤20% 时 GNOME 自动切 power-saver）。
- 🔧 移除 AB Download Manager 开机自启（备份在 `~/.cache/autostart-backup/`）。其浏览器插件经 Chrome 原生消息接口（`com.abdownloadmanager`，已注册）可在需要下载时唤起主程序（源码使用 IPC awaker）。需用户在 ABDM 设置中同时关闭“开机启动”，防止其重写自启项。

# 第三阶段：内存优化（2026-09-29）

- 背景：8 GB 内存、i5-8200Y。开机后可用约 4.9 GiB，内存压力 0，但 Chrome 多标签时容易吃紧。
- 🔧 **zram**：安装 Ubuntu 官方 `systemd-zram-generator`，`/etc/systemd/zram-generator.conf`：`ram / 2`（约 3.6 GiB）、zstd、优先级 100；原 4 GiB `/swap.img`（优先级 -1）保留作兜底。
  - ⚠️ 首次当场启动时算法是 lzo-rle，**重启后才变成 zstd**；之后每次开机都是 zstd。
- 🔧 **localsearch 索引范围收窄**：只递归索引 XDG 目录（文档、下载、图片、音乐、视频、桌面），`$HOME` 只扫第一层。
- 🔧 **停用桌面图标扩展** `ding@rastersoft.com`（常驻 gjs 进程约 100 MB）。
- 效果：开机 1 分钟时已用 1.7 GiB、可用 5.4 GiB（改之前开机 2 分钟时已用 2.2 GiB、可用 4.9 GiB；两次开的程序和开机时间不完全一样，仅供参考）。
- 保持不变：坚果云开机自启（用户选择）；GNOME 动画保持开启（用户选择）；Chrome 内存节省模式本来就开着；电源模式 balanced。
- 查过但不改：
  - Xwayland 一组（约 250 MB）：坚果云是 Java 程序，强制走 X11（`GDK_BACKEND=x11`），它在运行就必须有 Xwayland。
  - Evolution 数据服务（约 250 MB）：Google 账号的日历和联系人开着，顶栏日历要靠它。
  - 开机时间 39 s：固件 9 s + 引导 6.5 s，要动 BIOS/GRUB 才能改，不动。
- 待做：确认 Chrome 播放视频时是否用 VA-API 硬解（`chrome://media-internals` → `kVideoDecoderName`）；可选停用 ModemManager（本机没有移动网卡）。
