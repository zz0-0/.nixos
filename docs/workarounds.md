# 变通做法

> 对应：`nixos/hosts/zz2/`、`nixos/shared/boot.nix`、`nixos/shared/power.nix`

每条都写“什么时候可以删”。条件满足就删，不要留——留下的补丁会变成没人敢动的考古现场。

## NVIDIA RTD3（zz2）

**现象**：Linux 7.3 上内核线程以空的 nullfs root 启动，驱动对 `/sys/bus/pci/devices/<id>/config` 的 `filp_open()` 失败，运行时 D3 被禁用，RTX 5060 一直停在 D0。

**做法**：`nixos/hosts/zz2/patches/nvidia-rtd3-7.3.patch` 应用到 NVIDIA open module，把查找包进 `scoped_with_init_fs()`。

**移除条件**：上游驱动修好后，用不带补丁的构建，确认 `/proc/driver/nvidia/gpus/*/power` 显示 `Enabled (fine-grained)`，且空闲时 `runtime_status` 为 `suspended`。

## nvidia_uvm 延后加载（zz2）

**现象**：对 open 模块，nixpkgs 把 `nvidia_uvm` 直接塞进 `boot.kernelModules`（softdep 那条路对它无效）。`systemd-modules-load` 因此卡约 3 秒，而它是串行启动链的头：modules-load → firewall → NetworkManager → multi-user，占用户空间启动时间的三分之一。

**做法**：不动 `boot.kernelModules`（列表选项没有“减一项”的原语，`mkForce` 会连带吞掉 nixpkgs 以后新增的默认模块），改用 `environment.etc."modules-load.d/nixos.conf"` 覆盖成 `config.boot.kernelModules` 过滤掉 `nvidia_uvm` 的副本；模块仍会在 `multi-user.target` 之后由 `nvidia-uvm-load.service` 载入，CUDA 用得到时它已经在。

**移除条件**：nixpkgs 提供“不加载 nvidia_uvm”的开关，或 open 模块的 softdep 修好（那时删掉 `nixos/hosts/zz2/modules/boot-tuning.nix` 里那段即可）。验证：`systemd-analyze blame | grep modules-load` 从约 2 s 掉到几十毫秒，且 `/dev/nvidia-uvm` 在登录后存在、`nvidia-smi` 正常。

## systemd-boot 的 LoaderConfigTimeout

**现象**：NVRAM 里的 `LoaderConfigTimeout` 覆盖 `loader.conf`，重建和固件更新都不会清掉它，启动菜单会悄悄变回更长的超时。

**做法**：`nixos/shared/boot.nix` 在安装 bootloader 时清除这个 EFI 变量，让声明式的 `timeout` 说了算。

**移除条件**：systemd-boot 不再从 NVRAM 读取该值（或改为声明式管理）。验证：`od -An -tx1 -v /sys/firmware/efi/efivars/LoaderConfigTimeout-*` 在切换后不再出现。

## niri-display-power 用户服务

**现象**：开机即电池时，udev 事件早于合成器，刷新率切换没有生效。

**做法**：udev 规则只触发 `power-state-change.service`；刷新率由用户服务 `niri-display-power` 在 niri 启动后应用。

**移除条件**：合成器自己能可靠处理交流/电池切换，或 udev 能保证在合成器之后触发。验证：电池开机，检查当前模式是 `60.001` 而不是 `165`。

## Goodix 触摸板（zz2）

**现象**：需要打过补丁的 `hid-multitouch`（gt7868q）。

**做法**：`nixos/hosts/zz2/modules/goodix-custom-driver.nix` 构建带外模块。

**移除条件**：上游 `hid-multitouch` 合入该设备支持。**这个 bug 长期没人修，短期不要等**——保持现状即可。真要去掉时，验证：去掉模块重建重启，触摸板仍被识别并可多点触控。

## Intel 蓝牙（zz2）

**现象**：`btintel_pcie` 的 NULL-hdev 问题。

**做法**：带外模块 `nixos/hosts/zz2/modules/btintel-pcie-fix.nix`。

**移除条件**：上游修复。**同样长期没修，短期不要等**——保持现状。真要去掉时，验证：去掉模块重建重启，蓝牙能扫描并连接。
