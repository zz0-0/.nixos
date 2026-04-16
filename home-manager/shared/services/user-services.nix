{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  systemd.user.services.evolution = {
    Unit = {
      Description = "Evolution Mail and Calendar";
      After = [
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Wait for monitor setup + configure-niri-outputs to finish (~5s total)
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = "${pkgs.evolution}/bin/evolution";
      Restart = "no";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.teams-for-linux = {
    Unit = {
      Description = "Microsoft Teams for Linux";
      After = [
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Slightly longer delay so Evolution goes first
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 4";
      ExecStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --class \"teams-for-linux\"";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
