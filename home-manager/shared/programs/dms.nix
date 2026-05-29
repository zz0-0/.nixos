{ config, pkgs, ... }:

{
  programs.dank-material-shell = {
    enable = true;

    niri = {
      enableKeybinds = false;
      enableSpawn = false;  # systemd handles bar spawning (enableSpawn would duplicate)
    };

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = false;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
  };

}
