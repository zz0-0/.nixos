{
  config,
  lib,
  pkgs,
  ...
}:

# The btintel_pcie MSI-X IRQ handler can call
# btintel_pcie_dump_debug_registers() with a NULL hdev when an early GP1
# mailbox interrupt arrives during probe, causing a general protection
# fault ("Fixing recursive fault but reboot is needed!") and a hang at
# boot. The patch adds NULL hdev guards until this is fixed upstream.
#
# Checked against Linux 7.3: the kernel still dereferences hdev in this path,
# so the out-of-tree module is still required.
#
# Instead of boot.kernelPatches (which forces a full kernel rebuild on
# every kernel bump), build only the patched driver as an out-of-tree
# module. It is named btintel_pcie_fixed so the in-tree btintel_pcie can
# be blacklisted while this one binds the same PCI IDs.
let
  kernel = config.boot.kernelPackages.kernel;
  inherit (config.boot.kernelPackages) kernelModuleMakeFlags;
  cmdSign = lib.findFirst (flag: lib.hasPrefix "cmd_sign=" flag) "" kernelModuleMakeFlags;

  btintel-pcie-fixed = config.boot.kernelPackages.stdenv.mkDerivation {
    pname = "btintel-pcie-fixed";
    version = kernel.modDirVersion;
    src = kernel.src;

    nativeBuildInputs = [ kernel.dev ] ++ kernel.moduleBuildDependencies;

    unpackPhase = ''
      runHook preUnpack
      mkdir source
      cd source
      tar --wildcards --strip-components=3 -xf ${kernel.src} \
        '*/drivers/bluetooth/btintel_pcie.c' \
        '*/drivers/bluetooth/btintel_pcie.h' \
        '*/drivers/bluetooth/btintel.h'
      runHook postUnpack
    '';

    postPatch = ''
      patch -p3 < ${../patches/btintel-pcie-null-hdev.patch}
      cat > Makefile <<EOF
      obj-m += btintel_pcie_fixed.o
      btintel_pcie_fixed-y := btintel_pcie.o
      EOF
    '';

    buildPhase = ''
      runHook preBuild
      make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD \
        INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra \
        '${cmdSign}' \
        modules_install
      runHook postInstall
    '';
  };
in
{
  boot.extraModulePackages = [ btintel-pcie-fixed ];
  boot.kernelModules = [ "btintel_pcie_fixed" ];
  boot.blacklistedKernelModules = [ "btintel_pcie" ];
}
