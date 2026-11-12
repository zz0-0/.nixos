{
  ...
}:

# Intel Low Power Mode Daemon: on Core Ultra parts it moves background work to
# the E-cores and lowers the package's frequency floor, which is where most of
# the idle battery win on this generation comes from. The package ships a
# per-CPU-family config, and `intel_lpmd_config_F6_M204.xml` matches this
# Core Ultra 7 356H (family 6, model 204), so it has a profile for this chip.
#
# It is a separate layer from scx_lavd in nixos/shared/performance.nix: lavd
# decides which runnable task gets which CPU, LPMD constrains where the
# background cgroup may run at all. Both are on on purpose. Verify after
# switching:
#
#   systemctl status intel_lpmd
#   journalctl -b -u intel_lpmd
#
# If scheduling or responsiveness feels worse, stop them one at a time without
# a rebuild (`systemctl stop intel_lpmd`, then `scxctl stop`) before editing.
{
  services.intel-lpmd.enable = true;
}
