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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 6";
      ExecStart = "${pkgs.teams-for-linux}/bin/teams-for-linux";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
