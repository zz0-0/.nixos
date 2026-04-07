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
      ];
      shell = pkgs.bash;
    };
  };
}
