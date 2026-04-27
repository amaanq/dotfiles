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

    # Use stock kernel — bunker kernel patches are x86-specific
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # GCC 15 emits corrupted asm (0x1a chars) for some files on ppc64 cross.
    # Disable unnecessary drivers that trigger it — BATMAN_ADV is mesh
    # networking, useless on a server. Add more here if GCC 15 bites elsewhere.
    boot.kernelPatches = [
      {
        name = "ppc64-disable-useless-drivers";
        patch = null;
        extraConfig = ''
          BATMAN_ADV n
        '';
      }
    ];

    type = "server";

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    # nushell.nix is in disabledModules for ppc64 (deps like atuin/carapace
    # don't cross-compile), so /etc/nushell/config.nu is never generated.
    # Drop empty stubs so nushell can start at all.
    environment.etc."nushell/config.nu".text = "";
    environment.etc."nushell/env.nu".text = "";

    # common/nix.nix (disabledModules) normally enables nix-command + flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Many of your common/ and linux/ modules are in disabledModules for ppc64
    # (flake-input pkgs that can't cross-build). Put plain nixpkgs equivalents
    # here so basic dev/ops tools are present. TODO: factor into a per-server
    # ppc64 bootstrap module rather than duplicating on every ppc64 host.
    environment.systemPackages = [
      # Rust toolchain — desktop rust.nix uses fenix (no ppc64), and
      # `type = "server"` doesn't include it anyway. Stable nixpkgs rustc
      # only. The rustc-unwrapped overlay patches bootstrap's copy_link_internal
      # to survive symlink-over-dir collisions at compile.rs:830.
      #
      # Use rustc-unwrapped (the actual ppc64 ELF binary) instead of pkgs.rustc
      # (a runCommand-built bash wrapper). The wrapper's `#!@shell@` shebang
      # gets substituted with `pkgsBuildHost.bash` (an x86_64 ELF) because
      # runCommand always uses the build-host stdenv — making cargo fail to
      # exec rustc with `Exec format error (os error 8)`. The unwrapped binary
      # has none of the wrapper's flag-injection logic, but our build doesn't
      # need it (no sysroot override, no defaultArgs).
      pkgs.rustc-unwrapped
      pkgs.cargo
      # cargo invokes `cc` for linking. clang-wrapper provides `cc` and pulls
      # in binutils-wrapper for `ld`. Reuses LLVM 21 already in the rust
      # closure rather than pulling a separate gcc 15.
      pkgs.clang
      # rustfmt excluded: needs rustc_private for the TARGET (ppc64), but
      # rustc bootstrap only builds rustc_private for HOST. Cross-compile
      # is impossible without binfmt+QEMU emulation of ppc64 rustc on x86.
      # clippy excluded: same reason — depends on rustc-dev internals.
    ];

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
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      max = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHynM2pDVAe8ZlooMYFBTAhoEW1lV066GtoxjJJ0qEs6AAAAB3NzaDptYXg= max@privatevoid.net"
        ];
      };

      lillis = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYWWRfOsSpi7M6ejCEWHGTtsvOA8v7FiUOBR2If1nVa will.lillis24@gmail.com"
        ];
      };
    };

    networking = {
      hostName = "moraine";
      useDHCP = true;
    };

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
    # GRUB managed manually on PReP partition — disable NixOS installer
    # (install-grub.sh requires perl XML-LibXML which breaks in cross-compilation)
    boot.loader.grub.enable = lib.mkForce false;
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "25.11";

    time.timeZone = "America/Los_Angeles";
  }
)
