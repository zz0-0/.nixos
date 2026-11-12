# Runtime tuning

> 对应：`nixos/shared/performance.nix`、`nixos/shared/boot.nix`、`nixos/shared/nix.nix`、`nixos/hosts/zz2/modules/boot-tuning.nix`、`nixos/hosts/zz2/modules/intel-lpmd.nix`

这类机器通常被调错了顺序：人们改调度器和 sysctl，而真正的开销在一个永不入睡的 dGPU、一块电池上还跑 165 Hz 的屏幕、和一段根本没在硬件上解码的视频。最后那三条——见下面「电池」一节——加起来比这一页所有 sysctl 都值钱。

每一项都是一个有可验证主张的开关，并且**不重建就能撤销**：调不回来就只能信的调优，不如不调。

## CPU 调度：scx_lavd

`services.scx-loader` 开机加载 Valve 的 `scx_lavd`：延迟敏感的活留在 P-core，后台活压到 E-core，唤醒次数比 EEVDF 少而吞吐不低——正好是这台 16 线程混合架构机器同时要编译和打游戏的样子。

内核自己的调度器一直留着，所以这里没有不可逆的东西：

```bash
scxctl switch -s scx_bpfland   # 换个调度器试试
scxctl switch -s scx_lavd
scxctl stop                    # 回 EEVDF，本次开机有效
scxctl status
```

要长期换，改 `config.default_sched`。需要 6.12+ 内核——模块自带断言，内核降级会在构建期失败。

## 内核参数

| 参数 | 为什么 | 代价 |
|---|---|---|
| `preempt=full` | 这个内核是 `PREEMPT_DYNAMIC` + lazy 抢占，省上下文切换但放任任务等待；`full` 把等待时间压住，输入延迟和帧生成看得见 | 少量上下文切换吞吐 |
| `transparent_hugepage=always` | 不等 `madvise`，直接把匿名内存折叠成 2 MB 页 | 只触碰大页一部分的负载会多占内存 |
| `mitigations=off` | 见下文「安全换性能」 | 侧信道暴露 |
| `nmi_watchdog=0`、`usbcore.autosuspend=5` | 见 `nixos/shared/power.nix` | — |

## 压缩交换：zram

`zramSwap` 在优先级 100 上给机器一块压缩 swap，高于磁盘分区的 -1，所以普通内存压力永远碰不到 NVMe。`memoryPercent = 50` 是**设备容量**（30 G 内存的一半），不是它可能占用的内存：zstd 压缩后的数据在内存里大约是原来的三分之一。

```bash
zramctl                     # 设备、算法、当前占用
swapon --show               # zram 的 PRIO 必须高于分区
```

## sysctl

| sysctl | 为什么 |
|---|---|
| `vm.swappiness = 150` | 有 zram 时，换出一个匿名页比丢掉 page cache 便宜 |
| `vm.page-cluster = 0` | 每次换入一页；zram 一次解压完，读放大只浪费 cache |
| `vm.dirty_bytes = 2G` | 默认 20 % 会让 6 G 脏页攒着，大写入时全系统卡住 |
| `vm.dirty_background_bytes = 512M` | 提前开始回写，而不是最后一口气爆发 |
| `vm.overcommit_memory = 1` | 游戏和 JIT 会预留地址空间却从不全碰，默认启发式会拒绝 |
| `net.ipv4.tcp_congestion_control = bbr` | 这台机器实际走的高 RTT、有丢包的链路靠它保吞吐 |
| `net.core.default_qdisc = fq` | BBR 对应的 qdisc |
| `net.core.rmem_max/wmem_max = 16M` | 默认单流缓冲上限几 MB，再快的链路也用不满 |
| `net.ipv4.tcp_fastopen = 3` | 重复连接的握手省一个 RTT，浏览器和 substituter 全是重复连接 |

BBR 和 fq 是内核模块，所以 `tcp_bbr`、`sch_fq` 进了 `boot.kernelModules`；不加这两行，sysctl 会在开机时失败并被悄悄留在 cubic。验证：

```bash
sysctl vm.swappiness vm.dirty_bytes net.ipv4.tcp_congestion_control
```

同一模块里还有 `fileSystems."/".options = [ "noatime" ]`：relatime 仍会为每个读过的文件每天写一次 atime，而这里没有东西读 atime。

`systemd.oomd` 默认在 swap 用到 90 % 时杀进程；zram 是内核会先填满的 swap，那个阈值会在还有可回收内存时就开火。NixOS 的 option 只覆盖 `[OOM]` 段，所以用 drop-in 把 `[Swap] UsedLimit` 抬到 95 %。

## 图形

- `MESA_SHADER_CACHE_MAX_SIZE = 4G`：默认 1 GB，DXVK/Vulkan 游戏在缓存淘汰后会重编着色器，表现为首帧和打补丁后的卡顿。
- VA-API 见「电池」一节，它在 `nixos/hosts/zz2/modules/gpu.nix`。

## 电池

99 Wh 的电池如果只有 3–4 小时，那是 25–30 W——不是"Linux 费电"，是有东西没生效。实测（zz2，电池，亮度 150/496，浏览器挂着）：

| 状态 | 功耗 | 换算续航 |
|---|---|---|
| 165 Hz | 13.46 W | 7.3 h |
| 60 Hz | 9.52 W | 10.3 h |
| 60 Hz + 关掉模糊/动画 | 8.33 W | 11.7 h |

要再量任何一项，用 `scripts/power-triage.sh`：只读 sysfs/proc，不需要 root，把窗口内的
放电功率、CPU 占用、中断率、显示模式和 top 进程一起打出来。换桌面配置、换浏览器、
怀疑某个应用时，改一项跑一次 60 秒就有数，不用靠"好像省了点"。

**刷新率**：3.94 W 的差额。这条链曾经整条没生效过，原因和验证方式在
[docs/power.md](power.md)——输出名、`NIRI_SOCKET`、DMS 的显示器配置三处都能让它静默失效。

**硬件视频解码**：缺 `intel-media-driver` 时 libva 找不到 iHD 驱动，所有视频在 CPU 上软解，看片时多 5–10 W。Brave 本身早就带着 `--enable-features=AcceleratedVideoDecodeLinuxGL` 并且把 GPU 进程绑在显示用的那块 GPU 上，缺的只是驱动。验证：

```bash
# render 节点的编号每次开机都可能和上次相反，按驱动找，别记数字
XE=$(for n in /dev/dri/renderD*; do
       [ "$(basename "$(readlink -f "/sys/class/drm/$(basename "$n")/device/driver")")" = xe ] && echo "$n"
     done | head -1)
LIBVA_DRIVER_NAME=iHD vainfo --display drm --device "$XE"
```

能列出 `VAProfileAV1Profile0` / `HEVC` / `VP9` 的 `VAEntrypointVLD` 就说明硬解可用。
更进一步：Brave 的 GPU 进程里能 grep 到驱动，就说明它真的在用——

```bash
grep -l iHD_drv_video /proc/$(pgrep -f 'brave --type=gpu-process' | head -1)/maps
```

`chrome://gpu` 的 "Video Decode" 应显示 `Hardware accelerated`。

**Intel LPMD（仅 zz2）**：`services.intel-lpmd` 把后台活挪到 E-core 并压低封装频率地板。包里按 CPU family 分发配置，`intel_lpmd_config_F6_M204.xml` 正好对应这颗 Core Ultra 7 356H（family 6, model 204）。

```bash
systemctl status intel_lpmd
journalctl -b -u intel_lpmd
```

它和 `scx_lavd` 不是一层：lavd 决定一个可运行任务上哪个核，LPMD 限制后台 cgroup 能跑在哪些核上。机器感觉不对时，一次停一个（`systemctl stop intel_lpmd`、`scxctl stop`），都只对本次开机有效。

## 安全换性能：关闭 CPU 缓解

`nixos/hosts/zz2/modules/boot-tuning.nix` 里的 `mitigations=off`。对系统调用密集的活（编译、VM、Proton 编译着色器）是真实的百分比收益；代价同样真实——本机上已经在跑的代码可以触到那些被关闭的侧信道。攻击者仍需要先拿到本地代码执行，单人笔电上这不是主要威胁，这也是唯一支持这行的理由。

```bash
journalctl -k | grep -i mitigation
cat /sys/devices/system/cpu/vulnerabilities/*
```

删掉那一行就是完整的回退。

## 构建与下载

`nix.settings` 里 `http-connections = 32`、`max-substitution-jobs = 32`：一次重建通常卡在下载而不是编译，而 substituter 都在半个地球之外。`max-jobs`/`cores` 保持 4×4——16 线程已经打满，再高只会换来换页。

想再快就得上编译器缓存或远程构建，那属于项目级而不是系统级：devshell 里加 `ccache`（C/C++）或 `sccache`（Rust），`mold` 换链接器。`docs/packages.md` 里说的是装在哪，这里是"编译得快"。

## 刻意没调的

- **`snd_hda_intel power_save=1`**——现在已经是 `10`，改成 1 只省几百 mW，换来唤醒时的爆音。
- **`pcie_aspm.policy`**——NVMe 和 WiFi 链路的 L1 已经开着；再往上逼就是掉盘的来源。
- **充电上限**——这台机器的 `BAT0` 没有 `charge_control_end_threshold`，没有东西可写。
- **`/tmp` 上 tmpfs**——构建会明显变快，但 30 G 内存加大构建有 OOM 风险，需要单独决定。
- **`ibt=off`**——0–2 %，拿 CET 保护换，不划算。
- **CachyOS / zen 内核**——这个 nixpkgs rev 里没有对应包；自己打 BORE 补丁要连带重建 NVIDIA 和两个带外模块，成本远超收益。
- **`services.printing`（cups）**——socket 激活，常驻开销为零，关掉只会在要打印时添麻烦。
- **`ModemManager` 已关**（无 WWAN），`fwupd-refresh.timer` 已关（`fwupdmgr get-updates` 自己会刷新元数据）。
