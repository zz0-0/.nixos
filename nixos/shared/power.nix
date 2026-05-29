{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.upower.enable = true;

  # ── Power Profiles Daemon ──────────────────────────────────────────────
  # Switch profiles:  powerprofilesctl set power-saver|balanced|performance
  services.power-profiles-daemon.enable = true;

  # ── Thermald ───────────────────────────────────────────────────────────
  # Intel thermal daemon — prevents throttling, works alongside PPD.
  services.thermald.enable = true;

  # ── Powertop auto-tune ─────────────────────────────────────────────────
  # Handles PCIe runtime PM, USB autosuspend, SATA link power, WiFi power
  # save, audio codec power — all the kernel-level tuning TLP would do,
  # but without the ACPI lock hang.
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # ── Intel GPU power saving ─────────────────────────────────────────────
  boot.extraModprobeConfig = ''
    options i915 enable_fbc=1 enable_psr=1 enable_guc=3
  '';
}
