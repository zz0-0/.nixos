{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Goodix GXTP5100 Touchpad fix
  # This touchpad uses pressure-based input (ModelPressurePad=1)
  # Without this quirk, libinput doesn't properly process touch events
  # Reference: https://github.com/ty2/goodix-gt7868q-linux-driver

  # Install custom libinput quirks file to /etc/libinput/
  # libinput reads from both /usr/share/libinput/ and /etc/libinput/
  environment.etc."libinput/90-goodix-gxtp5100.quirks".text = ''
    [Goodix GXTP5100 Touchpad]
    MatchName=*GXTP5100*
    MatchUdevType=touchpad
    ModelPressurePad=1
    AttrPalmPressureThreshold=600
    AttrThumbPressureThreshold=1000
    AttrPressureRange=2:0
  '';
}
