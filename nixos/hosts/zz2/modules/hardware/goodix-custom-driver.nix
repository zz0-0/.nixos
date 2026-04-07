{
  config,
  pkgs,
  lib,
  ...
}:

# Custom Goodix GT7868Q driver for GXTP5100 touchpad
# GitHub: https://github.com/ty2/goodix-gt7868q-linux-driver
# This driver handles touchpads that fail with standard hid-multitouch due to HID descriptor issues

let
  # Fetch the driver source with correct hash
  goodix-src = pkgs.fetchFromGitHub {
    owner = "ty2";
    repo = "goodix-gt7868q-linux-driver";
    rev = "main";
    hash = "sha256-n1Xws5uEtFNenZau32cXvYyiUbhKvUlUf3LCcYZoD/Y=";
  };

  # Build the kernel module against the current kernel
  goodix-gt7868q = config.boot.kernelPackages.stdenv.mkDerivation {
    pname = "goodix-gt7868q";
    version = "unstable";

    # Use the original source (which includes hid-multitouch.c)
    src = goodix-src;

    nativeBuildInputs = [ config.boot.kernelPackages.kernel.dev ];

    # Patch for kernel 6.18+ timer API compatibility and add 0x01E7 device support
    postPatch = ''
      # Fix timer API changes in kernel 6.18+
      sed -i 's/del_timer(&td->release_timer)/timer_delete(\&td->release_timer)/g' hid-multitouch.c
      sed -i 's/del_timer_sync(&td->release_timer)/timer_delete_sync(\&td->release_timer)/g' hid-multitouch.c
      sed -i 's/struct mt_device \*td = from_timer(td, t, release_timer)/struct mt_device *td = container_of(t, struct mt_device, release_timer)/g' hid-multitouch.c

      # Add 0x01E7 device support
      sed -i '/0x01E8/a\\t    { HID_I2C_DEVICE(I2C_VENDOR_ID_GOODIX, 0x01E7) },' goodix-gt7868q.c
    '';

    buildPhase = ''
      make -C ${config.boot.kernelPackages.kernel.dev}/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/build M=$PWD modules
    '';

    installPhase = ''
      mkdir -p $out/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/kernel/drivers/hid
      cp goodix-gt7868q.ko $out/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/kernel/drivers/hid/
    '';
  };
in
{
  # Install the custom Goodix driver
  boot.extraModulePackages = [ goodix-gt7868q ];

  # Load the custom driver module
  boot.kernelModules = [ "goodix-gt7868q" ];

  # Blacklist the stock hid-multitouch and i2c-hid-acpi to prevent conflicts
  # The custom driver bundles its own patched hid-multitouch.c
  boot.blacklistedKernelModules = [
    "hid-multitouch"
    "i2c_hid_acpi"
  ];

  # Copy the libinput quirks file from the driver repository
  # This fixes pressure threshold issues that prevent cursor movement
  environment.etc."libinput/60-custom-goodix-gt7868q.quirks".source =
    "${goodix-src}/local-overrides.quirks";
}
