{
  pkgs,
  username,
  ...
}:

{
  programs.fish.enable = true;

  users.users = {
    ${username} = {
      isNormalUser = true;
      linger = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
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
      shell = pkgs.fish;
    };
  };
}
