{ config, lib, pkgs, ... }:

{
  # Enable realtime priority for audio (prevents dropout/glitches)
  security.rtkit.enable = true;

  # Enable PipeWire for audio (replaces PulseAudio)
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Enable WirePlumber session manager (includes Bluetooth auto-switch by default)
    wireplumber.enable = true;
  };
}
