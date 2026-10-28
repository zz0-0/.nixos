{
  config,
  pkgs,
  lib,
  ...
}:

# Goodix GT7868Q touchpad configuration for GXTP5100
#
# The touchpad generates proper X/Y events, but libinput uses pressure-based
# touch detection with autodetected thresholds (200:240) that are way too high
# for this device (actual touch pressure is 34-80). This causes libinput to
# reject all touches.
#
# Fix: Patch the bundled hid-multitouch.c to not register ABS_MT_PRESSURE.
# This forces libinput to fall back to BTN_TOUCH-based detection, which works.
#
# Checked against Linux 7.3: upstream hid-multitouch still lists Goodix
# 0x01E8/0x01E9 only, not this 0x01E7 device, and the pressure quirk is not
# upstream. Keep this out-of-tree driver until both land.

let
  kernel = config.boot.kernelPackages.kernel;
  inherit (config.boot.kernelPackages) kernelModuleMakeFlags;
  cmdSign = lib.findFirst (flag: lib.hasPrefix "cmd_sign=" flag) "" kernelModuleMakeFlags;

  # Pinned to c4c4cca (2025-08-02, current main) — bump deliberately and
  # update the hash when pulling a newer revision.
  goodix-src = pkgs.fetchFromGitHub {
    owner = "ty2";
    repo = "goodix-gt7868q-linux-driver";
    rev = "c4c4ccac098697d83a332aa512563133cb1f9199";
    hash = "sha256-n1Xws5uEtFNenZau32cXvYyiUbhKvUlUf3LCcYZoD/Y=";
  };

  goodix-gt7868q = config.boot.kernelPackages.stdenv.mkDerivation {
    pname = "goodix-gt7868q";
    version = "unstable";
    src = goodix-src;
    nativeBuildInputs = [
      config.boot.kernelPackages.kernel.dev
    ]
    ++ config.boot.kernelPackages.kernel.moduleBuildDependencies;

    postPatch = ''
      # Fix timer API changes in newer kernels
      sed -i 's/del_timer(&td->release_timer)/timer_delete(\&td->release_timer)/g' hid-multitouch.c
      sed -i 's/del_timer_sync(&td->release_timer)/timer_delete_sync(\&td->release_timer)/g' hid-multitouch.c
      sed -i 's/struct mt_device \*td = from_timer(td, t, release_timer)/struct mt_device *td = container_of(t, struct mt_device, release_timer)/g' hid-multitouch.c

      # Fix hid_report_raw_event API change in kernel 7.0+ (added bufsize parameter)
      # Old: hid_report_raw_event(hdev, type, buf, size, interrupt)
      # New: hid_report_raw_event(hdev, type, buf, bufsize, size, interrupt)
      sed -i 's/hid_report_raw_event(hdev, HID_FEATURE_REPORT, buf,/hid_report_raw_event(hdev, HID_FEATURE_REPORT, buf, size,/g' hid-multitouch.c

      # Add device ID 0x01E7
      sed -i '/0x01E8/a\\t    { HID_I2C_DEVICE(I2C_VENDOR_ID_GOODIX, 0x01E7) },' goodix-gt7868q.c

      # Disable ABS_MT_PRESSURE registration to work around broken pressure
      # thresholds (device reports 8-46, but libinput autodetects 200:240).
      # Without ABS_MT_PRESSURE, libinput falls back to BTN_TOUCH-based
      # touch detection, which works correctly.
      # 1. Don't register the ABS_MT_PRESSURE axis in input mapping (spans 2 lines)
      sed -i '/case HID_DG_TIPPRESSURE:/,/return 1;/{/set_abs(hi->input, ABS_MT_PRESSURE, field,/d; /cls->sn_pressure);/d; /MT_STORE_FIELD(p);/d}' hid-multitouch.c
      # 2. Don't emit ABS_MT_PRESSURE events in process_slot
      sed -i '/input_event(input, EV_ABS, ABS_MT_PRESSURE, \*slot->p);/d' hid-multitouch.c
    '';

    buildPhase = ''
      make -C ${config.boot.kernelPackages.kernel.dev}/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/build M=$PWD modules
    '';

    installPhase = ''
      runHook preInstall
      make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD \
        INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=kernel/drivers/hid \
        '${cmdSign}' \
        modules_install
      runHook postInstall
    '';
  };
in
{
  boot.extraModulePackages = [ goodix-gt7868q ];
  boot.kernelModules = [ "goodix-gt7868q" ];
  boot.blacklistedKernelModules = [ "hid-multitouch" ];
}
