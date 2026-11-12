{
  pkgs,
  ...
}:

{
  systemd.user.services.teams-for-linux = {
    Unit = {
      Description = "Microsoft Teams for Linux";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
      # An Electron app that lives in the tray does not need to start while the
      # machine is on battery. The condition gates autostart *and* an explicit
      # `systemctl --user start` — launching it from the DMS launcher still
      # works, because that runs the binary directly in its own scope.
      ConditionACPower = true;
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
