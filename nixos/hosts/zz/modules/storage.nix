{ config, pkgs, ... }:

{
  fileSystems."/mnt/drive" = {
    device = "/dev/disk/by-uuid/98427079-47ad-495a-b58f-ac3a155ea1ce";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
