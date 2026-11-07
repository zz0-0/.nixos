# dGPU runtime power on zz2

> 对应：`nixos/hosts/zz2/modules/gpu.nix`、`nixos/hosts/zz2/patches/nvidia-rtd3-7.3.patch`

NVIDIA 615 runs probe in an `nv-probe` kthread. On Linux 7.3, kthreads start
with an empty nullfs root, so the driver's `filp_open()` on
`/sys/bus/pci/devices/<id>/config` fails and the driver disables runtime D3.
This is why `/proc/driver/nvidia/gpus/*/power` said
`Runtime D3 status: Not supported` and the RTX 5060 never left D0.

`nixos/hosts/zz2/modules/gpu.nix` applies the CachyOS fix
(`nixos/hosts/zz2/patches/nvidia-rtd3-7.3.patch`) to the NVIDIA open module.
It wraps the lookup in `scoped_with_init_fs()` on 7.3+, so RTD3 reports
`Enabled (fine-grained)` again. The dGPU then enters D3cold when idle and
wakes automatically when `prime-run` or a game needs it.

After switching and rebooting, verify at idle:

```bash
cat /sys/bus/pci/devices/0000:02:00.0/power/runtime_status
cat /sys/bus/pci/devices/0000:02:00.0/power/runtime_suspended_time
nvidia-smi --query-gpu=name,pstate,power.draw --format=csv
cat /proc/driver/nvidia/gpus/*/power
```

