{ config, pkgs, ... }:

{
  imports = [ ../../shared/niri.nix ];

  config = {
    systemd.user.services.niri = {
      Unit = {
        Description = "A scrollable-tiling Wayland compositor";
        BindsTo = [ "graphical-session.target" ];
        Before = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" "xdg-desktop-autostart.target" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Slice = "session.slice";
        Type = "notify";
        ExecStart = "${config.programs.niri.package}/bin/niri --session";
        # Multi-GPU: do not restrict glvnd/Vulkan to Intel-only.
        # Without these overrides, niri auto-discovers both GPUs and creates
        # separate renderers per GPU — Intel for eDP, NVIDIA for HDMI.
        # NVIDIA stays in D3cold when no external monitor is connected.
        Environment = [];
      };
    };
  };
}
