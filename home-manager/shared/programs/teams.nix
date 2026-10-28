{
  config,
  pkgs,
  ...
}:

{
  systemd.user.services.teams-for-linux = {
    Unit = {
      Description = "Microsoft Teams for Linux";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 4";
      ExecStart = "${pkgs.teams-for-linux}/bin/teams-for-linux";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
