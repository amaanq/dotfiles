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

    # bunker kernel build hits a clang/lld discovery bug on ppc64. See
    # ppc64-overlay.nix's `linuxKernel.buildLinux` override for the full
    # explanation; this comment is just a pointer.

    # GCC 15 emits corrupted asm (0x1a chars) for some files on ppc64 cross,
    # AND also ICEs on some files (gfs2/rgrp.c in reload pass). Disable
    # unnecessary drivers to sidestep both:
    #   BATMAN_ADV — mesh networking, useless on server
    #   GFS2_FS    — Red Hat clustered FS, useless on server; ICEs at -O2
    # Add more here if GCC 15 bites elsewhere.
    boot.kernelPatches = [
      {
        name = "ppc64-disable-useless-drivers";
        patch = null;
        extraConfig = ''
          GFS2_FS n
          KSM n
        '';
      }
      {
        # pahole 1.31 segfaults on some ppc64 kernel modules (observed on
        # drivers/hwmon/ads7828.ko). Patch gen-btf.sh to skip BTF for
        # modules where pahole crashes — the module still links, BTF
        # introspection is lost only for those specific modules.
        name = "pahole-btf-crash-tolerance";
        patch = ./patches/kernel-btf-pahole-crashtolerance.patch;
      }
    ];

    # dmi_memory_id is now stubbed at the systemd derivation level (see
    # ppc64-overlay.nix), so we no longer need to override storePaths here.

    type = "server";

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    # nushell.nix module now enabled (was previously stubbed); it generates
    # /etc/nushell/config.nu and env.nu via its derivations.

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
      # exec rustc with `Exec format error (os error 8)` on tarn. The unwrapped
      # binary has none of the wrapper's flag-injection logic, but our build
      # doesn't need it (no sysroot override, no defaultArgs).
      #
      # `pkgs.rustc-unwrapped` resolves through `rustPackages_1_94` (the
      # overridden alias) so it picks up our ELFv2 target-spec patches.
      # `pkgs.rust_1_94.packages.stable.rustc-unwrapped` is the un-patched
      # vanilla nixpkgs scope used for bootstrapping.
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

    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      amaanq = {
        description = "Amaan Qureshi";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
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
      hostName = "tarn";
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
