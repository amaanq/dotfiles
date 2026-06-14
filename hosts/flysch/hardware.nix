{
  config,
  lib,
  pkgs,
  ...
}:
let
  buildPkgs = pkgs.buildPackages;
  # gen_init_cpio / gen_initramfs.sh come from the bunker kernel checkout used to
  # author the octeon patches (impure path; builds already run --impure to cross
  # to mips64).
  linuxSrc = /home/amaanq/projects/bunkernel/linux;

  # The PCIe-console ring corrupts data under full-duplex TCP in a way that
  # preserves IP/TCP checksums, so raw SLIP delivers garbage TCP/TLS. slipcrc
  # carries IP over the link with a per-frame CRC32 and drops failures, turning
  # the corruption into loss that TCP retransmits over. Replaces the kernel SLIP
  # ldisc; guyot's bridge speaks the same CRC32+SLIP wire format.
  slipcrc = pkgs.stdenv.mkDerivation {
    pname = "slipcrc";
    version = "1";
    dontUnpack = true;
    buildPhase = "$CC -O2 -Wall -o slipcrc ${./slipcrc.c}";
    installPhase = "install -Dm755 slipcrc $out/bin/slipcrc";
  };

  top = config.system.build.toplevel;
  closure = buildPkgs.closureInfo { rootPaths = [ top ]; };

  # The whole system closure becomes the initramfs; the ramfs the kernel unpacks
  # IS the root. No disk, no stage-1: /init is the stage-2 launcher, copied as a
  # regular file because 7.0's early init-exec can't follow a symlink into the
  # store. /bin/sh is seeded because stage-2-init runs the early mount script
  # through it before activation creates it.
  initramfsDir =
    buildPkgs.runCommand "flysch-initramfs-dir"
      {
        inherit top;
        storePaths = "${closure}/store-paths";
      }
      ''
        mkdir -p $out/nix/store $out/proc $out/sys $out/dev $out/run $out/tmp
        while read -r p; do
          cp -a "$p" "$out/nix/store/"
        done < "$storePaths"

        cp "$(readlink -f "$top/init")" $out/init
        chmod +x $out/init

        mkdir -p $out/bin
        ln -s ${config.environment.binsh} $out/bin/sh
      '';

  # An initramfs boot mounts no devtmpfs before /init runs, so /dev/console must
  # exist to wire up init's stdio. ttyPCI0/1 (4:96/4:97) are the two octeon
  # pci-console channels: 0 = kernel console + shell, 1 = the SLIP network link.
  initrdNodes = buildPkgs.writeText "flysch-initrd-nodes" ''
    dir /dev 0755 0 0
    nod /dev/console 0600 0 0 c 5 1
    nod /dev/null    0666 0 0 c 1 3
    nod /dev/zero    0666 0 0 c 1 5
    nod /dev/tty     0666 0 0 c 5 0
    nod /dev/ttyPCI0 0660 0 0 c 4 96
    nod /dev/ttyPCI1 0660 0 0 c 4 97
    nod /dev/kmsg    0644 0 0 c 1 11
    nod /dev/random  0666 0 0 c 1 8
    nod /dev/urandom 0666 0 0 c 1 9
  '';

  # A big initramfs can't be embedded in the kernel on OCTEON (image lives in the
  # low-512MB CKSEG0 window; the 0x10000000-0x1fffffff DRAM hole leaves ~192MB),
  # so the closure rides as a standalone cpio loaded high and handed over via
  # rd_start=. Uncompressed (newc magic 070701) so the kernel unpacks it with no
  # decompressor — the pure-Clang build miscompiles zlib_inflate.
  initramfsCpio = buildPkgs.runCommandCC "flysch-initramfs.cpio" { } ''
    mkdir -p usr
    $CC -O2 -o usr/gen_init_cpio ${linuxSrc}/usr/gen_init_cpio.c
    ${linuxSrc}/usr/gen_initramfs.sh -o $out \
      -u squash -g squash \
      ${initrdNodes} ${initramfsDir}
  '';

  # The card kernel: bunker octeon + the multi-channel pci-console driver dropped
  # in over the patched one (no bunker re-pin), the low CKSEG0 load address (the
  # SDK bootoctlinux only direct-loads images that fit its window; a higher/larger
  # image gets a broken "mapped" relocation and hangs before printk), SLIP for the
  # PCIe uplink, and the heavy octeon I/O dropped (the card is a PCIe endpoint:
  # no BGX NIC, no USB, no disk).
  cardKernel =
    (config.boot.kernelPackages.kernel.override (old: {
      structuredExtraConfig = (old.structuredExtraConfig or { }) // {
        # CN7890 has 48 cores and U-Boot starts every one (numcores=48), but
        # cavium_octeon_defconfig caps NR_CPUS at 32. The boot CPU then wedges in
        # early SMP bringup before printk — a silent hang right after U-Boot's
        # "Starting cores". Lift the cap past 48 so every core comes online.
        NR_CPUS = lib.mkForce (lib.kernel.freeform "64");
        # No RTC and almost no interrupt entropy, so the CRNG takes ~8 minutes to
        # initialise — ssh-keygen blocks on getrandom() and the whole boot stalls
        # behind it. Wire in the OCTEON hardware RNG so the pool seeds at once.
        HW_RANDOM = lib.mkForce lib.kernel.yes;
        HW_RANDOM_OCTEON = lib.mkForce lib.kernel.yes;
        OCTEON_ETHERNET = lib.mkForce lib.kernel.no;
        USB_SUPPORT = lib.mkForce lib.kernel.no;
        MMC = lib.mkForce lib.kernel.no;
        ATA = lib.mkForce lib.kernel.no;
        SCSI = lib.mkForce lib.kernel.no;
        # Plain SLIP only — NO Van Jacobson/CSLIP. With SLIP_COMPRESSED the driver
        # defaults to SL_MODE_ADAPTIVE, whose receiver auto-flips the link to CSLIP
        # outbound the instant it sees an inbound frame whose first byte is >= 0x70
        # — which a single corrupted byte on this lossy PCIe-console link produces.
        # Once flipped, the card VJ-compresses TCP headers that guyot's plain
        # RFC1055 bridge can't decode → silent TCP corruption (TLS/SSH never
        # complete, while ICMP/UDP — never VJ-compressed — look fine). Compiling out
        # CSLIP makes both directions unconditionally plain SLIP.
        SLIP = lib.kernel.yes;
        SLIP_COMPRESSED = lib.mkForce lib.kernel.no;
        SLIP_SMART = lib.kernel.yes;
        SLHC = lib.mkForce lib.kernel.no;
        # The card is diskless (RAM-root), so a persistent/large /nix/store has to
        # live on guyot and be reached over octc1: nbd-client maps a guyot-backed
        # block device to /dev/nbd0, ext4 (already =y) formats it, and overlayfs
        # layers it as the writable upper over the read-only RAM closure. Builtin
        # so no module juggling on this initramfs-only system.
        BLK_DEV_NBD = lib.mkForce lib.kernel.yes;
        OVERLAY_FS = lib.mkForce lib.kernel.yes;
      };
    })).overrideAttrs
      (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's|0xffffffff84000000|0xffffffff80800000|' arch/mips/cavium-octeon/Platform
          cp ${./octeon-pci-console.c} arch/mips/cavium-octeon/octeon-pci-console.c
          cp ${./octc1.c} drivers/net/octc1.c
          echo 'obj-y += octc1.o' >> drivers/net/Makefile
        '';
      });
in
{
  nixpkgs.hostPlatform = "mips64-unknown-linux-gnuabi64";
  nixpkgs.buildPlatform = "x86_64-linux";
  system.boot.loader.kernelFile = "vmlinux-${config.boot.kernelPackages.kernel.modDirVersion}";

  bunker.kernel = {
    octeon = true;
    lto = "none";
  };

  # No disk: root is the ramfs the kernel unpacked. tmpfs keeps
  # systemd-fstab-generator from emitting a mount/fsck unit.
  fileSystems = lib.mkForce {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
    };
  };
  boot.supportedFilesystems = lib.mkForce [ ];

  # No NixOS stage-1 at all: the hand-built initramfs above IS the root and
  # /init is the stage-2 launcher, so don't build the (deprecated scripted)
  # initrd that nothing would ever load.
  boot.initrd.enable = lib.mkForce false;

  boot.kernelParams = lib.mkForce [
    "console=pci0"
    "mem=0"
  ];
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # ttyPCI0: kernel console + an interactive root shell (debug/rescue).
  systemd.services."serial-getty@ttyS0".enable = lib.mkForce false;
  systemd.services.console-getty.enable = lib.mkForce false;
  systemd.services.card-shell = {
    description = "root shell on PCIe console ttyPCI0";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bashInteractive}/bin/bash --noprofile --norc -i";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/ttyPCI0";
      TTYReset = true;
      Restart = "always";
      RestartSec = 1;
      Environment = [
        "TERM=vt100"
        "HOME=/root"
        "PATH=/run/current-system/sw/bin"
      ];
    };
  };

  # ttyPCI1: a dedicated channel (no kernel console) carrying IP via slipcrc.
  # guyot is the peer at 10.99.0.1 and NATs the card to the LAN/internet. This is
  # the ONLY uplink, so it must come up BEFORE anything that needs the network —
  # NOT after multi-user.target: tailscaled-autoconnect blocks multi-user (its
  # long start timeout), so an After=multi-user ordering deadlocks (no network
  # until tailscale gives up, but tailscale needs the network).
  systemd.services.card-net = {
    description = "IP uplink (slipcrc) to guyot over PCIe console ttyPCI1";
    wantedBy = [
      "multi-user.target"
      "network-online.target"
    ];
    after = [ "network-pre.target" ];
    before = [
      "network-online.target"
      "tailscaled-autoconnect.service"
      "circus-agent.service"
    ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = pkgs.writeShellScript "flysch-net-up" ''
        (
          # slipcrc creates the octc0 tun; configure it once it appears. 576-byte
          # MTU keeps frames small (the ring corrupts large frames worse); guyot
          # clamps TCP MSS to match for forwarded traffic.
          for i in $(seq 1 80); do
            ${pkgs.iproute2}/bin/ip link show octc0 >/dev/null 2>&1 && break
            sleep 0.25
          done
          ${pkgs.iproute2}/bin/ip link set octc0 mtu 576 up
          ${pkgs.iproute2}/bin/ip addr add 10.99.0.2/30 dev octc0
          ${pkgs.iproute2}/bin/ip route add default via 10.99.0.1
          printf 'nameserver 1.1.1.1\n' > /etc/resolv.conf
        ) &
        exec ${slipcrc}/bin/slipcrc octc0 /dev/ttyPCI1
      '';
    };
  };

  # The card has no RTC, so it boots at the kernel's build epoch (months stale)
  # and every TLS handshake fails "certificate is not yet valid" — tailscale and
  # circus never connect. chronyd can't rescue it: NTP/UDP over the SLIP+NAT path
  # doesn't establish, and even if it did it would run after these services. So
  # step the clock from a plain-HTTP Date header (no TLS → immune to the very skew
  # we're fixing) before anything that needs a valid certificate. chronyd then
  # disciplines from here.
  systemd.services.card-clock = {
    description = "Step the wall clock from an HTTP Date header (card has no RTC)";
    wantedBy = [ "multi-user.target" ];
    after = [ "card-net.service" ];
    before = [
      "tailscaled-autoconnect.service"
      "circus-agent.service"
      "chronyd.service"
      "time-sync.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "card-clock" ''
        for i in $(seq 1 40); do
          for host in http://www.google.com/ http://cloudflare.com/ http://www.msftconnecttest.com/; do
            d=$(${pkgs.curl}/bin/curl -sI --max-time 8 "$host" 2>/dev/null \
                | ${pkgs.gnugrep}/bin/grep -i '^date:' \
                | ${pkgs.coreutils}/bin/cut -d' ' -f2- | ${pkgs.coreutils}/bin/tr -d '\r')
            if [ -n "$d" ]; then
              ${pkgs.coreutils}/bin/date -s "$d" && exit 0
            fi
          done
          sleep 3
        done
        exit 0
      '';
    };
  };

  # Make octc1 (the DMA-backed link to guyot, ~16 MB/s + 5ms vs SLIP's 32KB/s) the
  # PRIMARY uplink: bring up its address and REPLACE the default route to go via
  # guyot's octc1h (10.98.0.1). Ordered after card-net so this `replace` wins over
  # SLIP's default; octc0/SLIP stays up as a fallback path (no longer the default).
  # If octc1 is ever down (guyot's octcard-octc1 not running), recover over the
  # PCIe console: `ip route replace default via 10.99.0.1` to fall back to SLIP.
  systemd.services.card-octc1 = {
    description = "octc1 DMA link to guyot (primary uplink)";
    wantedBy = [ "multi-user.target" ];
    after = [ "card-net.service" ];
    before = [
      "network-online.target"
      "tailscaled-autoconnect.service"
      "circus-agent.service"
      "card-clock.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "card-octc1-up" ''
        for i in $(seq 1 40); do
          ${pkgs.iproute2}/bin/ip link show octc1 >/dev/null 2>&1 && break
          sleep 0.25
        done
        ${pkgs.iproute2}/bin/ip addr add 10.98.0.2/30 dev octc1 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set octc1 mtu 1500 up
        ${pkgs.iproute2}/bin/ip route replace default via 10.98.0.1 dev octc1
      '';
    };
  };

  system.build.cardKernel = cardKernel;
  system.build.cardInitramfs = initramfsCpio;
}
