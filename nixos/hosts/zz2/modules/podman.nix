{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Podman with NVIDIA runtime support
  virtualisation.podman = {
    enable = true;

    # Docker compatibility - creates /var/run/docker.sock
    dockerCompat = true;
  };

  # NVIDIA Container Toolkit configuration
  environment.etc."nvidia-container-toolkit/config.toml".text = ''
    [nvidia-container-cli]
    no-cgroups = true
    load-kernels = true

    [nvidia-container-runtime]
    runtime = "nvidia"
    runtimeArgs = ["--config=/etc/nvidia-container-runtime/config.toml"]
  '';

  # Environment variables for GPU access in containers
  environment.sessionVariables = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "all";
  };
}
