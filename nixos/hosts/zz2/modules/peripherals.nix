{
  pkgs,
  ...
}:

{
  # WiFi: Intel 8086:e340 (WiFi 7 BE202)
  # The stock iwlwifi/iwlmvm/btintel modules are left to udev autoload.
  # Loading them explicitly in boot.kernelModules put iwlmvm's firmware load
  # (about 1.6s) on the boot critical path. The custom btintel_pcie_fixed and
  # goodix-gt7868q modules stay explicit because they are not autoloaded.
  boot.kernelModules = [
    # I2C controllers needed for the Goodix touchpad via i2c_hid_acpi
    "i2c-designware-pci"
    "i2c-designware-core"
  ];

  # Kernel params for the PS/2 keyboard. The touchpad is I2C HID (GXTP5100 on
  # i2c-designware), so none of this is for it.
  boot.kernelParams = [
    "i8042.nopnp"

    # The EC emulates the internal keyboard on the i8042 KBD port. Probing the
    # AUX multiplexing controller at boot disturbs it: occasionally the kernel
    # logs "Spurious ACK" / "Unknown key released" and the keyboard then stops
    # delivering events until the next reboot (pointer and on-screen keyboard
    # keep working, so the desktop is healthy). Same mechanism as the Fujitsu
    # LIFEBOOK U7410 nomux quirk upstream.
    #
    # No PS/2 pointing device exists here: serio1-4 are unbound and psmouse has
    # no devices, so mux mode buys nothing and costs the keyboard.
    "i8042.nomux=1"
  ];

  # If touchpad or WiFi still doesn't work, run these and share output:
  #   dmesg | grep -iE 'i2c|hid|touchpad|elan|synaptics|goodix'
  #   libinput list-devices
  #   cat /proc/bus/input/devices | grep -A5 'Touchpad\|elan\|synaptics\|goodix'
  #   evtest /dev/input/event13  # test touchpad events directly
  #
  # For WiFi specifically, check if firmware loads:
  #   dmesg | grep iwlwifi
  # If you see "firmware: failed to load iwlwifi-gl-b0-fm-b0-XX.ucode",
  # we may need to manually add the firmware file.

  # Debug tools for touchpad/input issues
  environment.systemPackages = with pkgs; [
    libinput
    evtest
  ];
}
