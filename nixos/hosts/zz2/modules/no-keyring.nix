{ config, lib, ... }:

{
  # Disable gnome-keyring - not needed and causes password prompts on login
  services.gnome.gnome-keyring.enable = lib.mkForce false;
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.systemd-user.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.dms-greeter.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.sudo.enableGnomeKeyring = lib.mkForce false;
}
