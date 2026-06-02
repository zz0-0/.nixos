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
  # Intel thermal daemon — prevents throttling.
  services.thermald.enable = true;

  # ── Intel GPU power saving ─────────────────────────────────────────────
  # FBC: framebuffer compression, PSR: panel self-refresh, GuC: firmware
  boot.extraModprobeConfig = ''
    options i915 enable_fbc=1 enable_psr=1 enable_guc=3
  '';
}
