{ ... }:

{
  # Podman with NVIDIA GPU support
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

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
}
