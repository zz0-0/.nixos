# NixOS configuration

## 入口

```bash
./scripts/build-hosts.sh          # 构建 zz 和 zz2
nix flake check                   # 完整验证
```

新 clone 先跑 `./scripts/setup.sh`（设置 git hooks 路径）。push 前 `.githooks/pre-push` 会跑完整验证和文档指针检查。

## 闸门

切换系统只能走 `./scripts/switch-host.sh`。不要直接 `nixos-rebuild switch`——那会跳过构建、closure diff、确认和 GC。

不要单独跑 `home-manager switch`：它作为 NixOS 模块嵌入，单独跑会创建冲突的 profile。

## 密钥

`secrets/` 是 sops 加密的。不要打印解密后的值，不要写进文件或日志。解密只发生在需要它的那条命令里。
