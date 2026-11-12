{ ... }:

# The 34 GB swap partition used to be a reservation nothing ever touched: zram
# (priority 100) absorbs every ordinary memory-pressure event, so both swap
# devices sat at 0 B forever. Hibernation is what makes that partition earn its
# keep — 33.9 GB covers the 30 GB of RAM, and `resume=` tells the kernel where
# to look for the image after power-on.
#
# The trade is real: resume takes 10-20 s, and whether it works is a property
# of this firmware + driver combination, not of the config. Test it once before
# trusting it:
#
#   sudo systemctl hibernate      # powers off, screen goes black
#   # press the power button
#   journalctl -b | grep -i "PM: Image"
#
# "PM: Image successfully loaded" means it resumed. A fresh login screen means
# the image was not found or not written; delete this module and nothing else
# depends on it.
{
  boot.resumeDevice = "/dev/disk/by-uuid/4d34620c-51a7-4f0c-aaa3-97c6dbf26d60";

  # UPower's default at critical battery is HybridSleep: with no `resume=`
  # the image had nowhere to go, so losing power still lost the session. Now
  # that hibernation is wired up, write the image and power off instead.
  services.upower.criticalPowerAction = "Hibernate";
}
