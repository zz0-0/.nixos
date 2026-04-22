{
  services.upower.enable = true;

  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      # CPU governor: performance on AC, powersave on battery
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # SATA link power: max_performance on AC, med_power_with_dipm on battery
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # WiFi power saving: off on AC, on battery
      WIFI_PWR_ON_BAT = "on";

      # Runtime PM: on for AC and battery (auto lets TLP decide)
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };
}
