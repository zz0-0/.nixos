{ username, ... }:

{
  # Secrets are decrypted at activation by sops-nix. The age private key lives
  # outside the repo; back it up. The matching public key is in .sops.yaml.
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
}
