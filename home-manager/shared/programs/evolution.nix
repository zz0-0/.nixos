{
  pkgs,
  ...
}:

let
  # Wait for niri's Wayland socket instead of assuming the systemd user
  # manager has already imported WAYLAND_DISPLAY. Without Xorg there is no
  # DISPLAY fallback, so an early start used to fail with "cannot open display".
  evolutionLauncher = pkgs.writeShellApplication {
    name = "evolution-launcher";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      if [ -z "''${WAYLAND_DISPLAY:-}" ] || [ ! -S "$runtime_dir/''${WAYLAND_DISPLAY}" ]; then
        unset WAYLAND_DISPLAY
        for _ in {1..50}; do
          for socket in "$runtime_dir"/wayland-*; do
            [ -S "$socket" ] || continue
            display="$(basename "$socket")"
            export WAYLAND_DISPLAY="$display"
            break 2
          done
          sleep 0.2
        done
      fi

      if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
        echo "no Wayland socket found in $runtime_dir" >&2
        exit 1
      fi

      exec ${pkgs.evolutionWithPlugins}/bin/evolution
    '';
  };
in
{
  systemd.user.services.evolution = {
    Unit = {
      Description = "Evolution Mail and Calendar";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${evolutionLauncher}/bin/evolution-launcher";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
