{ config, pkgs, ... }:

{
  powerManagement.powertop.enable = true;

  # NOTE: Update this with your actual disk UUIDs after running nixos-generate-config on zz2
  # fileSystems."/mnt/drive" = {
  #   device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };
}
