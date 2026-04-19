{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  users.users = {
    ${username} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "podman"
      ];
      subUidRanges = [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
      shell = pkgs.bash;
    };
  };
}
