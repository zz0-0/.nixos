# Per-host power settings

> 对应：`nixos/shared/power.nix`、`nixos/hosts/zz2/default.nix`

`nixos/shared/power.nix` applies display brightness and refresh-rate changes
on AC/battery switches. The option defaults are intentionally `null` — a host
opts in by setting values. zz2 sets its 3200x2000 panel values in
`nixos/hosts/zz2/default.nix`; zz leaves them unset.

```nix
laptop.display = {
  output = "eDP-1";
  backlight = "intel_backlight";
  brightnessAC = 496;
  brightnessBattery = 150;
  modeAC = "3200x2000@165.000";
  modeBattery = "3200x2000@60.001";
};
```

`laptop.wifi.interface` opts into the same service toggling WiFi power saving
(off on AC, on on battery). zz2 sets it to `wlp0s20f3`.

The udev rule now only triggers `power-state-change.service`; the service sets
brightness and the power profile. A user service (`niri-display-power`) applies
the refresh rate after niri starts, which fixes the old boot-on-battery case
where the udev event ran before the compositor existed.

