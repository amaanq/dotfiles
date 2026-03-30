# ppc64 Big Endian ELFv2 package fixes for cross-compilation.
# Ported from obscure-arches flake — handles broken tests, missing
# cross-compile support, and ppc64-specific build failures.
{ lib, ... }:
{
  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.overlays = [
    (_: prev: {
      # Rust: add powerpc64-unknown-linux-gnuelfv2 target
      rustc-unwrapped = prev.rustc-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/rust-ppc64-elfv2-target.patch ];
        configureFlags = map (
          f:
          builtins.replaceStrings
            [ "powerpc64-unknown-linux-gnu" ]
            [ "powerpc64-unknown-linux-gnuelfv2" ]
            (toString f)
        ) (old.configureFlags or [ ]);
      });

      # Non-EFI grub can't build for ppc64 ELFv2
      grub2 = prev.grub2.overrideAttrs (_: { meta = { }; });
      grub2_efi = prev.grub2.overrideAttrs (_: { meta = { }; });

      # openssl asm broken on BE
      openssl = prev.openssl.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "no-asm" ];
      });

      # Disabled test suites — fail or hang on ppc64
      nix = prev.nix.overrideAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
      git = prev.git.override {
        doInstallCheck = false;
        rustSupport = false;
      };
      coreutils = prev.coreutils.overrideAttrs (_: { doCheck = false; });
      coreutils-full = prev.coreutils-full.overrideAttrs (_: { doCheck = false; });
      findutils = prev.findutils.overrideAttrs (_: { doCheck = false; });
      byacc = prev.byacc.overrideAttrs (_: { doCheck = false; });
      bmake = prev.bmake.overrideAttrs (_: { doCheck = false; });

      # Perl cross-compilation: Alien-Build's devdoc output never created because
      # cross-compiled perl can't run File::Temp/IPC::Cmd. perl.override{overrides}
      # doesn't propagate into the package scope's internal deps (drv hash unchanged).
      # Workaround: bypass consumers — stub moreutils (uses perl.withPackages which
      # pulls Alien-Build transitively), and install-grub.sh is handled by disabling
      # the GRUB installer (we manage PReP boot manually on tarn).
      moreutils = prev.moreutils.overrideAttrs (_: {
        buildInputs = [ prev.perl ];
        postInstall = "";
      });

      # Python test/build fixes
      python313 = prev.python313.override {
        packageOverrides = _: pyprev: {
          filelock = pyprev.filelock.overrideAttrs (_: { doInstallCheck = false; });
          cryptography-vectors = pyprev.cryptography-vectors.overrideAttrs (_: {
            nativeBuildInputs = [ ];
            buildPhase = "mkdir -p $out $dist";
            installPhase = "true";
            dontUsePypaInstall = true;
          });
          cryptography = pyprev.cryptography.overrideAttrs (_: { doInstallCheck = false; });
        };
      };

      # switch-to-configuration-ng: test failures + missing dbus dep
      switch-to-configuration-ng = prev.switch-to-configuration-ng.overrideAttrs (old: {
        doCheck = false;
        preCheck = "true";
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.dbus.dev ];
      });

      # polkit: SUID chmod fails in user namespace
      polkit = prev.polkit.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/0o4755/0o755/' meson_post_install.py
        '';
      });

      # dbus: SUID + chown fail in user namespace; break lib↔out cycle
      dbus = prev.dbus.overrideAttrs (old: {
        postPatch = ''
          sed -i -e 's/stat.S_ISUID | //' -e '/os.chown/d' meson_post_install.py
        '';
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.removeReferencesTo ];
        postFixup = (old.postFixup or "") + ''
          find $lib -type f \( -name '*.so*' -o -executable \) -exec remove-references-to -t $out {} + || true
        '';
      });

      # jemalloc needs autotools for ppc64
      jemalloc = prev.jemalloc.overrideAttrs (_: {
        nativeBuildInputs = [ prev.autoconf prev.automake ];
      });

      # newt: configure picks up host Debian tclConfig.sh causing segfault
      newt = prev.newt.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "--without-tcl" ];
      });

      # protobuf: tests fail on ppc64
      protobuf = prev.protobuf.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-Dprotobuf_BUILD_TESTS=OFF" ];
      });

      # zfs bash-completion path fix
      zfs = prev.zfs.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--with-bash-completiondir=${placeholder "out"}/share/bash-completion/completions"
        ];
      });

      # groff: broken PDF in doc output
      groff = prev.groff.overrideAttrs (_: {
        postFixup = "rm -f $doc/share/doc/groff-1.23.0/pdf/mom-pdf.pdf";
      });

      # ppc64 isn't EFI — stub out EFI packages
      gnu-efi = prev.emptyDirectory // { dev = prev.emptyDirectory; };
      fwupd-efi = prev.emptyDirectory;

      # deno doesn't support ppc64
      deno = prev.emptyDirectory // { meta = { mainProgram = "deno"; }; };

      # openstackclient pulls in reno which breaks cross-compilation
      openstackclient = prev.emptyDirectory;

      # GCC 15 gfortran segfaults on ppc64 ELFv2 — stub out Fortran + BLAS/LAPACK
      gfortran = prev.emptyDirectory;
      blas = prev.runCommand "blas-stub" {
        passthru = {
          isILP64 = false;
          implementation = "openblas";
          provider = "blas-stub";
        };
        dev = prev.emptyDirectory;
      } "mkdir -p $out/lib/pkgconfig $out/include; touch $out/lib/libblas.so $out/include/cblas.h";

      lapack-reference = prev.runCommand "lapack-stub" {
        passthru = {
          isILP64 = false;
          implementation = "openblas";
          provider = "lapack-stub";
        };
        dev = prev.emptyDirectory;
      } "mkdir -p $out/lib/pkgconfig $out/include; touch $out/lib/liblapack.so $out/include/lapacke.h";

      liblapack = prev.runCommand "lapack-stub" {
        passthru = {
          isILP64 = false;
          implementation = "openblas";
          provider = "lapack-stub";
        };
        dev = prev.emptyDirectory;
      } "mkdir -p $out/lib/pkgconfig $out/include; touch $out/lib/liblapack.so $out/include/lapacke.h";

      lapack = prev.runCommand "lapack-stub" {
        passthru = {
          isILP64 = false;
          implementation = "openblas";
          provider = "lapack-stub";
        };
        dev = prev.emptyDirectory;
      } "mkdir -p $out/lib/pkgconfig $out/include; touch $out/lib/liblapack.so $out/include/lapacke.h";
    })
  ];

  # Disable ZFS (broken on ppc64 ELFv2)
  boot.supportedFilesystems = lib.mkForce [ "bcachefs" ];
  boot.zfs.forceImportAll = lib.mkForce false;
  boot.zfs.forceImportRoot = lib.mkForce false;

  # Disable polkit (broken in cross-compilation)
  security.polkit.enable = lib.mkForce false;

  # Disable modules that reference flake packages not available for powerpc64-linux
  # Disable modules that reference flake packages not available for powerpc64-linux
  disabledModules = [
    ../../modules/linux/run0.nix
    ../../modules/common/neovim.nix
    ../../modules/common/jujutsu.nix
    ../../modules/common/claude-code/default.nix
    ../../modules/common/agenix.nix
    ../../modules/linux/server/restic/default.nix
    ../../modules/linux/tailscale/default.nix
    ../../modules/common/shell/aliases.nix
    ../../modules/common/shell/nushell.nix
    ../../modules/common/ssh/default.nix
    ../../modules/common/atuin/default.nix
    ../../modules/common/git.nix
    ../../modules/common/nix.nix
    ../../modules/linux/atuin.nix
    ../../modules/linux/server/restic/default.nix
    ../../modules/linux/tailscale/default.nix
    ../../modules/acme/default.nix
  ];
  security.sudo.enable = lib.mkDefault true;

  # Suppress extra dependencies the ISO module adds
  system.extraDependencies = lib.mkForce [ ];
}
