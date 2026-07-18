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
    # Mark USB devices as not ready on remove so systemd doesn't wait for them
    ACTION=="remove", SUBSYSTEM=="usb", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Don't wait for NVIDIA GPU during shutdown
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # btintel_pcie Bluetooth controller (PCI 8086:e376) intermittently wedges
    # its driver in uninterruptible (D) state. On shutdown, systemd-udevd
    # spawns a worker on the remove uevent that touches the wedged device and
    # blocks until udev's event_timeout kills it -> long shutdown stall.
    # Match on ENV{PCI_ID} (present on remove uevents; ATTR{} sysfs reads may
    # not resolve as the device goes away) so systemd never waits on the unit.
    # The stuck-worker timeout is capped globally via udev.event_timeout in
    # the kernel params (see peripherals.nix), since event_timeout is no
    # longer a valid per-rule OPTIONS key in modern udev.
    ENV{PCI_ID}=="8086:E376", TAG+="systemd", ENV{SYSTEMD_READY}="0"
    SUBSYSTEM=="bluetooth", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Enable USB autosuspend for power saving (~1-3W savings)
    # Devices wake automatically on activity.
    # If a specific device misbehaves (mouse/keyboard lag), blacklist it:
    #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="xxxx", ATTR{idProduct}=="yyyy", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
  '';

  # HP Thunderbolt Dock G2 authorization at boot and resume
  systemd.services.hp-thunderbolt-dock = {
    description = "Authorize HP Thunderbolt Dock G2";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo hp-dock > /dev/kmsg; sleep 2; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; echo done > /dev/kmsg'";
      # Re-authorize on service stop (which happens on suspend)
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo hp-dock-stop > /dev/kmsg; sleep 1; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true'";
    };
  };

  # Re-authorize HP Thunderbolt Dock G2 and power USB devices after resume from suspend
  systemd.services.systemd-suspend = {
    serviceConfig = {
      ExecStopPost = "${pkgs.bash}/bin/bash -c 'echo resume > /dev/kmsg; sleep 2; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; for d in /sys/bus/usb/devices/3-4 /sys/bus/usb/devices/3-6; do echo on > $d/power/control 2>/dev/null || true; done; echo done > /dev/kmsg'";
    };
  };
}
