# NixOS 配置

zz / zz2 两台机器的 NixOS + Home Manager。flake + lock 钉住全部输入，sops 管密钥。

## 命令

```bash
./scripts/build-hosts.sh [host]   # 快速构建：切换前用
./scripts/switch-host.sh [host]   # 构建 → 差异 → 确认 → 切换（唯一入口）
nix flake check                    # 完整验证：两台都构建
```

`nix flake check` 是**验证**；`build-hosts.sh` 是切换前的**快速构建**。两者都不改动系统。

没有 CI。push 前由 [.githooks/pre-push](.githooks/pre-push) 跑完整验证和文档指针检查——这是唯一的自动关卡。新 clone 先跑一次 `./scripts/setup.sh`，它把 git hooks 路径指过去。

`nixos-rebuild` 是唯一入口。flake 有意不暴露 `homeConfigurations`：单独跑 `home-manager switch` 会创建第二个 profile，遮蔽 NixOS 托管的那份。

## 结构

- `nixos/shared/` —— 两台机器共同的系统模块
- `nixos/hosts/<host>/` —— 单机差异：硬件、GPU、外设、驱动补丁
- `home-manager/` —— 用户环境，作为 NixOS 模块嵌入

依赖方向：host 可以 import shared，shared 不能假设某个 host。需要单机行为时加 option，在 host 里设值。

## 不显然的

- 不要单独跑 `home-manager switch`。
- age 私钥不在仓库里；丢了，`secrets/` 就解不开。
- 重型 GUI 走 `nix profile`，不进系统闭包。

## 专题

| 文件 | 回答什么 |
|---|---|
| [docs/workarounds.md](docs/workarounds.md) | 哪些是临时补丁，各自什么时候能删 |
| [docs/packages.md](docs/packages.md) | 装在哪里：声明式、`nix profile`、还是 `nix run` |
| [docs/secrets.md](docs/secrets.md) | sops + age，含轮换和恢复 |
| [docs/new-host.md](docs/new-host.md) | 加一台机器 |
| [docs/architecture.md](docs/architecture.md) | 模块依赖方向 |
| [docs/gpu-power.md](docs/gpu-power.md) | zz2 的 dGPU 运行时电源 |
| [docs/boot-time.md](docs/boot-time.md) | 启动时间花在哪 |
| [docs/power.md](docs/power.md) | 交流/电池切换时的亮度与刷新率 |
| [docs/emacs.md](docs/emacs.md) | Emacs 与 devshell 的 Eglot 接线 |
| [docs/firmware.md](docs/firmware.md) | fwupd |
