# Per-host power settings

> 对应：`nixos/shared/power.nix`、`nixos/hosts/zz2/default.nix`

`nixos/shared/power.nix` applies display brightness and refresh-rate changes
on AC/battery switches. The option defaults are intentionally `null` — a host
opts in by setting values. zz2 sets its 3200x2000 panel values in
`nixos/hosts/zz2/default.nix`; zz leaves them unset.

```nix
laptop.display = {
  output = "eDP-1";          # 只是提示，见下面「输出名会变」
  backlight = "intel_backlight";
  brightnessAC = 496;
  brightnessBattery = 150;
  modeAC = "3200x2000@165.000";
  modeBattery = "3200x2000@60.001";
};
```

`laptop.wifi.interface` opts into the same service toggling WiFi power saving
(off on AC, on on battery). zz2 sets it to `wlp0s20f3`.

The udev rule triggers `power-state-change.service`; the service sets
brightness, the power profile and WiFi power saving, and applies the refresh
rate itself when a session is already up. The user service
(`niri-display-power`) does the same at login, when niri exists but the udev
event that fired during boot did not.

## 三个会让它静默失效的陷阱

**输出名会变，所以不能写死。** 这台机器上 Intel 和 NVIDIA 两块 GPU 会轮流占用
`eDP-1` / `eDP-2` 这两个名字，取决于 probe 顺序——7.3.1 时面板是 `eDP-2`，
升到 7.3.4 之后变成 `eDP-1`，NVIDIA 那张卡的编号同时从 `eDP-1` 换到 `eDP-2`。
写死名字的策略是"撑到下次重启"。

所以 `laptop.display.output` 只是**提示**：两个脚本都先看配置的名字在不在
niri 的输出列表里，不在就退回第一个 `eDP-*` / `LVDS*` 连接器。真名随时可查：

```bash
niri msg outputs | grep -E '^Output|Current mode'
```

而且 `niri msg output <错名字> mode ...` **返回 0**，只是把变更排队等那个连接器
出现——这也是为什么它曾经静默失效了很久。现在找不到面板会写进 journal 并
`exit 1`，不再假装成功。

**`niri msg` 需要 `NIRI_SOCKET`。** 只设 `WAYLAND_DISPLAY` 会得到
`NIRI_SOCKET is not set, are you running this within niri?`。socket 名字里带
niri 的 pid，不能拼，只能扫 `$XDG_RUNTIME_DIR/niri.*.sock`——系统级服务看不到
用户的会话环境，所以它自己扫。

**DMS 也会应用显示器配置。** `~/.config/DankMaterialShell/monitors.json` 里
存着输出配置（`mode` 含刷新率），`displayProfileAutoSelect = true` 时 shell
启动会照着它重设一次，把刷新率拉回 165。这个开关现在是 `false`，刷新率因此
只由这套服务决定。若哪天 shell 升级后重置了配置，先看这个键：

```bash
python3 -c 'import json,pathlib;print(json.loads((pathlib.Path.home()/".config/DankMaterialShell/settings.json").read_text()).get("displayProfileAutoSelect"))'
```

即使它又被打开，下一次插拔电源也会把模式纠正回来——udev 事件是最后说话的人。

## 实测

zz2，电池，亮度 150/496，浏览器挂着：

| 状态 | 功耗 | 换算续航 |
|---|---|---|
| 165 Hz | 13.46 W | 7.3 h |
| 60 Hz | 9.52 W | 10.3 h |
| 60 Hz + 关掉模糊/动画 | 8.33 W | 11.7 h |
| 加上 Vulkan pin，Brave + Zed 轻量使用 | 7.30 W | 13.4 h |

数字是 `scripts/power-triage.sh` 采的（电池上跑，60 秒）。改完这条链之后要复核，
先拔电源，再 `./scripts/power-triage.sh 60`，看 `average draw` 和 `Current mode` 两行。

刷新率一项就是 **3.94 W**。这也是为什么这条链必须验证：按 60 Hz 做的预算，
如果脚本没生效，算出来的续航和实际差三个小时。
