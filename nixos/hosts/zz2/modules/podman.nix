{
  lib,
  pkgs,
  ...
}:

{
  # Enable container support
  virtualisation.containers.enable = true;

  # Podman configuration
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
  };

  # Search registries for container images
  virtualisation.containers.registries.search = [ "docker.io" ];

  # Enable NVIDIA container toolkit support
  hardware.nvidia-container-toolkit.enable = true;

  # CDI directories
  systemd.tmpfiles.rules = [
    "d /etc/cdi 0755 root root -"
    "d /var/run/cdi 0755 root root -"
  ];

  # Environment variables for GPU access in containers
  environment.sessionVariables = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "all";
  };

  # Add podman-compose package for running docker-compose.yaml files
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
