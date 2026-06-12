{ pkgs, lib, ... }:
{
  # Push the RAM-root NixOS image onto the CN7890 LiquidIO card over PCIe at
  # boot. The card has no disk and is host-booted: guyot loads the kernel +
  # initrd over the PCIe BAR and runs bootoctlinux. Artifacts + the OCTEON SDK
  # host tools live under /var/lib/octcard (kept out of /tmp, which is wiped).
  systemd.services.octcard-boot = {
    description = "Boot RAM-root NixOS on the CN7890 LiquidIO card over PCIe";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.cpio
      pkgs.age # decrypt flysch's host key from the guyot-only blob
      pkgs.openssh # ssh-keygen -y to derive the pubkey for the overlay
    ];
    unitConfig.ConditionPathIsReadWrite = "/var/lib/octcard/boot.sh";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash /var/lib/octcard/boot.sh";
      # the card may already be running from a prior push; a re-push just resets
      # and reboots it, so a failed/declined run is never fatal to guyot.
      SuccessExitStatus = "0 1";
    };
  };

  # guyot's end of the card's PRIMARY uplink: octhost masters the PCIe BAR and
  # gives a DMA-backed virtual NIC (tun octc1h, ~16 MB/s + 5ms vs SLIP's 32KB/s),
  # plus NAT so the card reaches the LAN/internet over it. Card is 10.98.0.2,
  # guyot 10.98.0.1. Restart=always retries until the card's octc1 module is up.
  # Conflicts with octcard-net (both want the single BAR window), so starting the
  # SLIP fallback automatically stops this and vice-versa.
  systemd.services.octcard-octc1 = {
    description = "octc1 DMA uplink + NAT for the CN7890 card (primary)";
    wantedBy = [ "multi-user.target" ];
    after = [ "octcard-boot.service" ];
    conflicts = [ "octcard-net.service" ];
    path = [ pkgs.bash pkgs.iproute2 pkgs.iptables pkgs.procps pkgs.coreutils pkgs.gnugrep pkgs.systemd ];
    unitConfig.ConditionPathIsReadWrite = "/var/lib/octcard/octc1-svc.sh";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash /var/lib/octcard/octc1-svc.sh";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # SLIP uplink over the PCIe console channel 1 (tun octcard0 <-> oct-remote-pipe)
  # + NAT, card 10.99.0.2 / guyot 10.99.0.1. Now the FALLBACK: not started at boot
  # (octc1 is primary); `systemctl start octcard-net` activates it, which conflicts
  # octcard-octc1 and frees the BAR. (Then set the card's default back to SLIP over
  # the console.)
  systemd.services.octcard-net = {
    description = "SLIP uplink + NAT for the CN7890 card (fallback)";
    after = [ "octcard-boot.service" ];
    conflicts = [ "octcard-octc1.service" ];
    path = [
      pkgs.python3
      pkgs.iproute2
      pkgs.iptables
      pkgs.procps
      pkgs.coreutils
      pkgs.util-linux
      pkgs.gawk # host-net.sh derives the LAN egress iface via awk
    ];
    unitConfig.ConditionPathIsReadWrite = "/var/lib/octcard/host-net.sh";
    serviceConfig = {
      # The SLIP bridge is the service's MAIN process, supervised + restarted by
      # systemd directly. (Detaching it from a oneshot via setsid was fragile and
      # kept dying.) host-net.sh runs as ExecStartPost on each (re)start to
      # configure octcard0 + NAT once the bridge has created the tun.
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 /var/lib/octcard/slip-bridge.py";
      ExecStartPost = "${pkgs.bash}/bin/bash /var/lib/octcard/host-net.sh";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
