{
  config,
  pkgs,
  username,
  ...
}:

let
  # NixOS assigns the uid at activation time, so it is null here. The first
  # user is 1000; if that ever stops being true the only loss is the ordering
  # below (an After= on an unknown unit is a no-op), not correctness.
  uid = config.users.users.${username}.uid;
  uid' = if uid == null then 1000 else uid;
  runtimeDir = "/run/user/${toString uid'}";
in

{
  services = {
    printing.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
  };

  # ── Shutdown hang ──────────────────────────────────────────────────────────
  # gvfsd-fuse exports two FUSE mounts, /run/user/<uid>/gvfs and ~/.gvfs. When
  # they are busy at shutdown, the umount lands in uninterruptible sleep;
  # SIGKILL does not help, so the user manager sits in its stop job until
  # TimeoutStopSec expires. user@.service ships 120s, which is the "shutting
  # down and nothing happens" people end up holding the power button over —
  # and that is what leaves the root filesystem dirty ("Dirty bit is set" on
  # the next fsck).
  #
  # Two independent measures, because either one alone still leaves a hole:
  #
  # 1. 30s instead of 120s. A hung user manager now costs half a minute, not
  #    two. `asDropin` is essential: the default strategy would replace the
  #    packaged user@.service with a unit that has no ExecStart.
  systemd.services."user@".overrideStrategy = "asDropin";
  systemd.services."user@".serviceConfig.TimeoutStopSec = "30s";

  # 2. Detach the FUSE mounts lazily while gvfs is still healthy. `umount -l`
  #    only drops the mount from the namespace, so no process can get stuck on
  #    a busy FUSE. Ordered After the user manager, which on shutdown means
  #    this unit stops before it — after login it is simply active.
  systemd.services.gvfs-lazy-unmount = {
    description = "Detach gvfs FUSE mounts before the user manager stops";
    wantedBy = [ "multi-user.target" ];
    after = [ "user@${toString uid'}.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = pkgs.writeShellScript "gvfs-lazy-unmount" ''
        ${pkgs.util-linux}/bin/umount -l ${runtimeDir}/gvfs /home/${username}/.gvfs 2>/dev/null || true
      '';
    };
  };
}
