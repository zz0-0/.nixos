{
  config,
  pkgs,
  dmsPkg,
  ...
}:

{
  programs.dank-material-shell = {
    enable = true;
    package = dmsPkg;

    niri = {
      enableKeybinds = false;
      enableSpawn = false; # systemd handles bar spawning (enableSpawn would duplicate)
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
