{
  pkgs,
  ...
}:

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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = "${pkgs.evolutionWithPlugins}/bin/evolution";
      Restart = "no";
    };
  };
}
