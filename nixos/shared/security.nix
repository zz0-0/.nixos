{ ... }:

{
  # Polkit is enabled by default. Do not auto-approve every wheel action:
  # any process in the user session could otherwise use pkexec to become root
  # without a password. NixOS already ships scoped rules for NetworkManager
  # and CUPS; add narrow allowlist rules here only if a specific action needs
  # passwordless approval.
  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  # Auto-unlock gnome-keyring with login password via PAM.
  security.pam.services = {
    login.enableGnomeKeyring = true;
    greetd.enableGnomeKeyring = true;
  };
}
