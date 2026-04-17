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

    # Use NVIDIA container runtime
    dockerCompat = true;

    # Required for GPU passthrough in containers
    defaultRuntime = "nvidia";
    runtime = pkgs.nvidia-container-runtime;
  };

  # NVIDIA Container Toolkit configuration for podman
  environment.etc."nvidia-container-toolkit/config.toml".text = lib.generators.toTOML { } {
    nvidia-container-cli = {
      no-cgroups = true;
      load-kernels = true;
    };
    nvidia-container-runtime = {
      runtime = "nvidia";
      runtimeArgs = [ "--config=/etc/nvidia-container-runtime/config.toml" ];
    };
  };

  # Ensure NVIDIA libraries are accessible to containers
  environment.sessionVariables = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "all";
  };
}
