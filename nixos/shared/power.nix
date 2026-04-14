{ config, lib, ... }:

{
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  services.upower.enable = true;
}
