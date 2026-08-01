{
  config,
  lib,
  pkgs,
  ...
}:

{
  # AGGRESSIVE SHUTDOWN: short timeouts, kill stuck services fast
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "5s"; # was 10s - only wait 5s before SIGKILL
    DefaultTimeoutStartSec = "5s";
    # Fail fast - don't retry failing services
    StartLimitIntervalSec = "1s";
    StartLimitBurst = "2";
  };

  services.udev.extraRules = ''
    # Don't wait for NVIDIA GPU during shutdown
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Enable USB autosuspend
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
  '';
}
