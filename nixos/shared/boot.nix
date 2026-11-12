{
  pkgs,
  ...
}:

let
  # The default is 5 seconds. Two seconds still leaves time to pick an older
  # generation, without adding 5s to every boot.
  menuTimeout = 2;
in
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;

        # systemd-boot keeps an explicitly chosen menu timeout in the
        # LoaderConfigTimeout EFI variable, and that NVRAM value overrides
        # loader.conf. A stale value survives rebuilds and firmware updates,
        # which makes `timeout` above look like it was reverted. Clear it when
        # the bootloader is installed so the declarative value is authoritative.
        extraInstallCommands = ''
          ${pkgs.systemd}/bin/bootctl set-timeout ""
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = menuTimeout;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # nvidia-drm.modeset=1 is added automatically by hardware.nvidia.modesetting.enable

    # The loader reads the whole initrd from the FAT ESP before the kernel
    # starts, and the ~40 MB is dominated by the 15 MB Intel microcode blob and
    # systemd userspace, so the compressor is a read-time/size tradeoff rather
    # than a space win. zstd decompresses several times faster than xz for a
    # modestly larger file: the ESP read is sequential and cheap, the
    # decompression is on the critical path.
    #
    # The initrd itself is systemd-based already — nixpkgs removed the scripted
    # initrd, so there is nothing to opt into here.
    initrd.compressor = "zstd";
  };
}
