{
  services.upower.enable = true;

  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      # ============================================
      # CPU - Power save on battery, performance on AC
      # ============================================
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MIN_PERF_ON_BAT = 5;
      CPU_MAX_PERF_ON_BAT = 30;
      CPU_MIN_PERF_ON_AC = 50;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_HWP_ON_BAT = "balance_power";
      CPU_HWP_ON_AC = "performance";

      # ============================================
      # Intel P-State - Hybrid P-core/E-core management
      # ============================================
      INTEL_PSTATE_HWP_ON_BAT = "balance_power";
      INTEL_PSTATE_HWP_ON_AC = "performance";
      INTEL_PSTATE_MIN_PERF_ON_BAT = 5;
      INTEL_PSTATE_MAX_PERF_ON_BAT = 30;
      INTEL_PSTATE_MIN_PERF_ON_AC = 50;
      INTEL_PSTATE_MAX_PERF_ON_AC = 100;

      # ============================================
      # WiFi - Power saving on battery
      # ============================================
      WIFI_PWR_ON_BAT = "off";
      WIFI_PWR_ON_AC = "on";

      # ============================================
      # Disk - Aggressive spindown on battery
      # ============================================
      DISK_APM_LEVEL_ON_BAT = "254 254";
      DISK_APM_LEVEL_ON_AC = "254 254";

      # ============================================
      # Runtime PM - Aggressive for all devices
      # ============================================
      RUNTIME_PM_ON_BAT = "on";
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_FORCE = "on";

      # ============================================
      # Sound card - Reduce power on battery
      # ============================================
      SOUND_POWER_SAVE_ON_BAT = "Y";
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      SOUND_POWER_SAVE_ON_AC = "N";
    };
  };
}
