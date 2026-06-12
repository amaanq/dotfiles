lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    pkgs,
    lib,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    # The Cavium OCTEON III CN7890 LiquidIO card living inside guyot: a RAM-rooted
    # 48-core mips64 build runner, reached over the PCIe SLIP uplink. Its own
    # identity, not varve (which is the EdgeRouter Infinity).
    type = "server";
    isBuilder = true;
    builderSpeedFactor = 1;
    builderMaxJobs = 12;

    networking = {
      hostName = "flysch";
      # the uplink is the static SLIP link brought up by card-net, not DHCP.
      useDHCP = lib.mkForce false;
      # The trimmed card kernel drops most netfilter modules (no xt LOG target,
      # no pkttype match, …), so nixos-fw-* rule setup fails and firewall.service
      # dies anyway. The card is a private build runner reached only through
      # guyot's NAT and the tailnet (ACL-gated), so run no host firewall here.
      firewall.enable = false;
    };

    # The root is a tmpfs the kernel unpacks the initramfs into, and rootfs comes
    # up mode 1777 (world-writable). sshd's StrictModes then refuses every key
    # ("bad ownership or modes for directory /"), locking out all logins. Tighten
    # it before sshd starts.
    system.activationScripts.tightenRoot = "chmod 0755 /";

    # No disk and a fresh closure every boot: automatic GC/optimise are useless
    # and actively dangerous here — when card-clock steps the wall clock months
    # forward, nix-gc.timer fires "overdue" and collects paths of the *running*
    # RAM-root system (it ate /run/current-system once).
    nix.gc.automatic = lib.mkForce false;
    nix.optimise.automatic = lib.mkForce false;

    # No flake registry on the card: the default nixpkgs pin drags its entire
    # ~196MB source into the closure, which then has to ride the PCIe push and
    # unpack into tmpfs on every boot. Nothing here resolves flake refs.
    nix.registry = lib.mkForce { };
    nix.settings.flake-registry = lib.mkForce "";

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    # Standard fleet users + secrets via agenix, same as every host. The only
    # twist for the RAM-root: guyot injects flysch's SSH host key into the initrd
    # at boot (see hardware.nix), which is what lets agenix decrypt the rest.
    secrets.password.rekeyFile = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };

      amaanq = {
        description = "Amaan Qureshi";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # The card is diskless, so its persistent/large /nix/store lives on guyot and
    # is reached over octc1 as an NBD block device: nbd-client maps it, e2fsprogs
    # formats/repairs the ext4 on it. (overlayfs + nbd are builtin to the kernel.)
    environment.systemPackages = with pkgs; [
      nbd
      e2fsprogs
    ];

    # systemd's seccomp SystemCallFilter and MemoryDenyWriteExecute break thread
    # creation and Go syscalls on mips64 (chronyd dies in pthread_create,
    # node-exporter takes a SIGSYS register-dump). circus-agent dies earlier still:
    # the mips64 libgcc_s.so.1 carries an executable-stack GNU_STACK header, so
    # ld.so's mprotect to make the stack executable is what MemoryDenyWriteExecute's
    # seccomp filter rejects ("cannot enable executable stack ... Permission denied").
    # All three run fine unsandboxed.
    #
    # TODO: VERIFY/FIX
    systemd.services.chronyd.serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };
    systemd.services.prometheus-node-exporter.serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };
    systemd.services.circus-agent.serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };

    # card-clock orders before this and fixes the headscale TLS-cert "not yet
    # valid" failure, but the uplink still races boot, so keep retrying instead
    # of failing the boot once.
    systemd.services.tailscaled-autoconnect = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Restart = lib.mkForce "on-failure";
        RestartSec = 10;
        TimeoutStartSec = lib.mkForce "180";
      };
    };

    system.stateVersion = "26.05";
    time.timeZone = "America/New_York";
  }
)
