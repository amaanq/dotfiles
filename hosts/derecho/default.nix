lib:
lib.nixosSystem' "desktop" (
  {
    config,
    keys,
    lib,
    pkgs,
    nix-src,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "desktop";
    cpuArch = "MZEN5";
    isBuilder = true;
    builderSpeedFactor = 4;
    builderMaxJobs = 32;

    networking.hostName = "derecho";

    displayOutputs = {
      "DP-1" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 239.991;
        };
        scale = 1.25;
        position = {
          x = 3072;
          y = 0;
        };
      };
      "DP-2" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 160.0;
        };
        scale = 1.25;
        position = {
          x = 0;
          y = 0;
        };
      };
    };

    secrets.password.rekeyFile = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
      };

      amaanq = {
        description = "Amaan Qureshi";
        extraGroups = [
          "gamemode"
          "wheel"
        ];
        isNormalUser = true;
        homeMode = "755";
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };
    };

    boot.binfmt.preferStaticEmulators = true;
    boot.binfmt.emulatedSystems = [
      "powerpc64le-linux"
      "powerpc64-linux"
      "riscv64-linux"
      "s390x-linux"
      "mips64el-linux"
    ];

    # Manual registration for e2k — standard qemu lacks e2k support;
    # uses OpenE2K's qemu-e2k fork for user-mode emulation
    boot.binfmt.registrations."e2k-linux" =
      let
        qemu-e2k = pkgs.callPackage ../../pkgs/qemu-e2k/package.nix { };
      in
      {
        interpreter = "${qemu-e2k}/bin/qemu-e2k";
        magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xaf\x00'';
        mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        preserveArgvZero = true;
        fixBinary = true;
        wrapInterpreterInShell = false;
      };

    # Manual registration for aarch64_be — nixpkgs has a bug where
    # qemuArch returns "aarch64" instead of "aarch64_be" for big-endian
    boot.binfmt.registrations."aarch64_be-linux" = {
      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-aarch64_be";
      magicOrExtension = ''\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7'';
      mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff'';
      preserveArgvZero = true;
      fixBinary = true;
      wrapInterpreterInShell = false;
    };

    boot.tmp = {
      useTmpfs = true;
      tmpfsSize = "16G";
    };

    nix.package = lib.mkForce nix-src.packages.${pkgs.system}.nix;

    system.stateVersion = "25.11";

    time.timeZone = "America/New_York";
  }
)
