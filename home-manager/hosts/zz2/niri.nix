{ config, pkgs, ... }:

{
  imports = [ ../../shared/niri.nix ];

  config = {
    systemd.user.services.niri = {
      Unit = {
        Description = "A scrollable-tiling Wayland compositor";
        BindsTo = [ "graphical-session.target" ];
        Before = [ "graphical-session.target" ];
        Wants = [
          "graphical-session-pre.target"
          "xdg-desktop-autostart.target"
        ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Slice = "session.slice";
        Type = "notify";
        ExecStart = "${config.programs.niri.package}/bin/niri --session";
        # niri auto-discovers both GPUs and creates a renderer per GPU:
        # Intel for eDP, NVIDIA for HDMI. The NVIDIA GPU is only kept awake
        # while an output is connected to it; the actual dGPU runtime-D3
        # behaviour is controlled by the kernel/NVIDIA driver, not by this
        # unit. Do not force a single renderer through environment variables
        # here, or HDMI output stops working.
      };
    };
  };
}
