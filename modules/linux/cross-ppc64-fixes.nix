# ppc64 Big Endian ELFv2 package fixes for cross-compilation.
# Auto-imported on every linux host; the overlay self-gates so it's a no-op
# unless the host is a cross-compiled ppc64 target. Top-level config attrs
# below also gate on `config.nixpkgs.hostPlatform.isPower64`.
{
  config,
  lib,
  ...
}:
let
  isPower64 = config.nixpkgs.hostPlatform.isPower64 or false;
in
{
  config = lib.mkIf isPower64 {
    nixpkgs.config.allowUnsupportedSystem = true;

    nixpkgs.overlays = [
      (final: prev: {
        # Bump rust to 1.95.0 (nixpkgs staging PR #510674, merged
        # 2026-04-22, not yet in nixos-unstable). 1.95 includes the
        # powerpc64 callconv fix (PR #150468) — without it, rustc emits
        # indirect-return setups for ≤16-byte aggregates on ppc64 BE
        # ELFv2 while LLVM emits ELFv2 register returns, corrupting every
        # `extern "C"` aggregate return (bcachefs-tools' superblock csum
        # was the visible casualty).
        #
        # Replace `rust_1_94` with a fresh callPackage of nixpkgs's
        # rust/default.nix using the 1.95 args. Overriding only
        # `rustPackages_1_94.rustc-unwrapped` is insufficient — the rust
        # scope's `buildRustPackages` recurses through `pkgsBuildHost.rust_1_94`
        # to bootstrap, and sees the original `rustcVersion = "1.94.0"` from
        # the un-overridden `rust_1_94`, triggering rustc-1.94 builds that
        # then fail because stage0 is now 1.95.
        #
        # Drop this hack once nixpkgs unstable ships 1_95.nix.
        rust_1_94 =
          let
            llvmSharedFor =
              pkgSet:
              pkgSet.llvmPackages.libllvm.override (
                {
                  enableSharedLibraries = true;
                }
                // lib.optionalAttrs (prev.stdenv.targetPlatform.useLLVM or false) {
                  stdenv = pkgSet.stdenv.override {
                    allowedRequisites = null;
                    cc = pkgSet.pkgsBuildHost.llvmPackages.clangUseLLVM;
                  };
                }
              );
          in
          import "${prev.path}/pkgs/development/compilers/rust/default.nix"
            {
              rustcVersion = "1.95.0";
              rustcSha256 = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";

              llvmSharedForBuild = llvmSharedFor prev.pkgsBuildBuild;
              llvmSharedForHost = llvmSharedFor prev.pkgsBuildHost;
              llvmSharedForTarget = llvmSharedFor prev.pkgsBuildTarget;

              inherit (prev) llvmPackages cargo-auditable;
              llvmShared = llvmSharedFor prev.pkgsHostTarget;

              # Rust N can build rust N+1, so 1.94 stage0 → 1.95 stage1 works.
              # Keep the 1.94 prebuilt bootstrap to avoid downloading 1.95
              # binary tarballs (bootstrapHashes) for every host arch.
              bootstrapVersion = "1.94.0";

              bootstrapHashes = {
                i686-unknown-linux-gnu = "4c309c178f96770968ce79226af935996b1715389abf4bc08bdd4f596660201d";
                x86_64-unknown-linux-gnu = "3bb1925a0a5ad2c17be731ee6e977e4a68490ab2182086db897bd28be21e965f";
                x86_64-unknown-linux-musl = "d64e9c6e93d00cf7d56c6dd8e3fbb127aef7d0e0c45da18cd49daafce1da38da";
                arm-unknown-linux-gnueabihf = "2abf1ca017b0762f0750bcebff1c4814805a28c66935c09139d2adf3565105c6";
                armv7-unknown-linux-gnueabihf = "338514f8c7adccb67c851ce220baceef0cec53b26291ae805094dbdbb5ceaad1";
                aarch64-unknown-linux-gnu = "a0dc5a65ab337421347533e5be11d3fab11f119683a0dbd257ef3fe968bd2d72";
                aarch64-unknown-linux-musl = "8ff50ffcf1da9aaea29767864abcdc4cce2eb840d3200e9a3ff585ad17f002b8";
                x86_64-apple-darwin = "97724032da92646194a802a7991f1166c4dc9f0a63f3bb01a53860e98f31d08c";
                aarch64-apple-darwin = "94903e93a4334d42bb6d92377a39903349c07f3709c792864bcdf7959f3c8c7d";
                powerpc64-unknown-linux-gnu = "34dcc95d487f5a7da33ec05abf394515f80559d030e45b1c1744e2005690d720";
                powerpc64le-unknown-linux-gnu = "fc6fa22878c5d12cb60e0ebaffdad70161965719bcc5d0b6793b132a0de8f759";
                powerpc64le-unknown-linux-musl = "52472bac4cdecb95e7a091ad9bb328747a09b8cfe7082a90511d5250a330cdbc";
                riscv64gc-unknown-linux-gnu = "ee71279fee2755d7f613597b24c8b168cc4e404d17e4e966c6b92aaf4d3c21ef";
                s390x-unknown-linux-gnu = "a27d205e95d9e1ec3f14d94c2cc28b1b6d3b64dda50c1f25a787a30989782a18";
                loongarch64-unknown-linux-gnu = "12361da66b693b848f6908d2321d03bb53ee9037bcc3d406876e6fc7b945e23d";
                loongarch64-unknown-linux-musl = "42278996624153a2b872905be08796515e49079dfcdee5f28d4c389f18c2f0e5";
                x86_64-unknown-freebsd = "6fba7bf41553e67b6d0f2014f7e128818b92f215b1e96a100ac5eaed06a41a04";
              };

              selectRustPackage = pkgs: pkgs.rust_1_94;
            }
            {
              inherit (prev)
                stdenv
                lib
                newScope
                callPackage
                pkgsBuildBuild
                pkgsBuildHost
                pkgsBuildTarget
                pkgsTargetTarget
                makeRustPlatform
                wrapRustcWith
                ;
            };

        # Override the alias (NOT `rust_1_94.packages.stable`). The rust scope's
        # internal `buildRustPackages = (selectRustPackage pkgsBuildHost).packages.stable`
        # uses the un-patched stable scope, so the bootstrap chain stays vanilla
        # (the bootstrap rustc just needs to compile rust 1.95 from source — it
        # doesn't need our ELFv2 target spec since it produces x86 code, and
        # patching it ALSO changes its hash → triggers a stage1 rebuild that
        # then panics at compile.rs:815 because the bootstrap-time invariants
        # we're patching shift around). Top-level `pkgs.rustc` resolves to
        # `rustPackages_1_94.rustc` though, so the FINAL cross rustc IS built
        # with our patches applied to its source, just from a vanilla bootstrap.
        rustPackages_1_94 = final.rust_1_94.packages.stable.overrideScope (
          _: rprev: {
            rustc-unwrapped = rprev.rustc-unwrapped.overrideAttrs (old: {
              patches =
                # Drop nixpkgs's ignore-missing-docs.patch (1.95's
                # library/core/src/os/mod.rs already has the inner attr).
                lib.filter (p: !(lib.hasSuffix "ignore-missing-docs.patch" (toString p))) (old.patches or [ ])
                ++ [
                  ./patches/rust-ppc64-elfv2-target.patch
                  ./patches/rust-bootstrap-symlink-over-dir.patch
                ];
              # rustc / LLVM 21.1.8 crashes with SIGSEGV in
              # llvm::UpgradeGlobalVariable while parsing ThinLTO bitcode for
              # regex-syntax during stage2-tools. The crash is in the ThinLTO
              # import path; bootstrap defaults rust.lto to ThinLocal. Force off.
              configureFlags = (old.configureFlags or [ ]) ++ [
                "--set=rust.lto=off"
                # error_index_generator is built as a target (ppc64 BE) binary
                # but needs to run on the build host (x86) to generate HTML
                # error docs. Disable docs entirely on this server.
                "--set=build.docs=false"
              ];
              env = (old.env or { }) // {
                RUST_MIN_STACK = "16777216";
              };
            });
          }
        );

        # Host GCC 15.2 ICEs in the einline GIMPLE pass at -O2 compiling
        # gcc/ipa-cp.cc when building the ppc64 cross-gcc. Overriding the
        # stdenv globally (to gcc14Stdenv) trips the stdenv bootstrap
        # assertion (prevStage.gcc-unwrapped must be bootstrap-built), so
        # patch the source: drop ipa-cp.cc and ipa-icf-gimple.cc to -O1 via
        # a file-scope optimize pragma.
        #
        # MUST be conditional on targetPlatform.isPowerPC64: overrideAttrs
        # applies to every splice, and unconditionally patching the source
        # changes the hash of the NATIVE x86 gcc-unwrapped too — forcing a
        # full x86 stdenv bootstrap rebuild (stages 0→4 + xgcc) on every
        # build. Native x86 GCC 15 doesn't hit this ICE, so skip it there.
        gcc-unwrapped =
          if prev.stdenv.targetPlatform.isPower64 then
            prev.gcc-unwrapped.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                for f in gcc/ipa-cp.cc gcc/ipa-icf-gimple.cc; do
                  if [ -f "$f" ] && ! grep -q 'pragma GCC optimize' "$f"; then
                    sed -i '1i #pragma GCC optimize("-O1")' "$f"
                  fi
                done
              '';
            })
          else
            prev.gcc-unwrapped;

        # Non-EFI grub can't build for ppc64 ELFv2
        grub2 = prev.grub2.overrideAttrs (_: {
          meta = { };
        });
        grub2_efi = prev.grub2.overrideAttrs (_: {
          meta = { };
        });

        # systemd: dmi_memory_id is x86-only (reads SMBIOS) and skipped on
        # ppc64. nixpkgs' udev.nix unconditionally adds it to
        # boot.initrd.systemd.storePaths, so make-initrd-ng panics with "file
        # does not exist". Drop a no-op shell stub at that path on ppc64 so the
        # store reference resolves; udev's rule for memory devices gracefully
        # fails to match when the helper exits 0 with no output.
        #
        # `[ -d $out/lib/udev ]` skips outputs that don't ship udev helpers
        # (e.g. systemdLibs's libs-only output) — those don't have lib/udev/
        # at all, so creating dmi_memory_id there would fail.
        systemd =
          if prev.stdenv.hostPlatform.isPower64 then
            prev.systemd.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                echo "[ppc64 dmi_memory_id stub postFixup] outputs=$outputs out=$out"
                if [ -d "$out/lib/udev" ]; then
                  if [ ! -e "$out/lib/udev/dmi_memory_id" ]; then
                    chmod +w "$out/lib/udev"
                    printf '#!/bin/sh\nexit 0\n' > "$out/lib/udev/dmi_memory_id"
                    chmod 555 "$out/lib/udev/dmi_memory_id"
                    chmod -w "$out/lib/udev"
                    echo "[ppc64 dmi_memory_id stub postFixup] created $out/lib/udev/dmi_memory_id"
                  else
                    echo "[ppc64 dmi_memory_id stub postFixup] already exists at $out/lib/udev/dmi_memory_id"
                  fi
                else
                  echo "[ppc64 dmi_memory_id stub postFixup] $out/lib/udev does not exist; skipping"
                fi
              '';
            })
          else
            prev.systemd;
        systemdMinimal =
          if prev.stdenv.hostPlatform.isPower64 then
            prev.systemdMinimal.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                echo "[ppc64 dmi_memory_id stub min postFixup] outputs=$outputs out=$out"
                if [ -d "$out/lib/udev" ] && [ ! -e "$out/lib/udev/dmi_memory_id" ]; then
                  chmod +w "$out/lib/udev"
                  printf '#!/bin/sh\nexit 0\n' > "$out/lib/udev/dmi_memory_id"
                  chmod 555 "$out/lib/udev/dmi_memory_id"
                  chmod -w "$out/lib/udev"
                  echo "[ppc64 dmi_memory_id stub min postFixup] created"
                fi
              '';
            })
          else
            prev.systemdMinimal;

        # openssl asm broken on BE
        openssl = prev.openssl.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [ "no-asm" ];
        });

        # nodejs: GCC 15 ICE in V8 at -O3 on ppc64 (cross-heap-remembered-set.h)
        nodejs-slim = prev.nodejs-slim.overrideAttrs (old: {
          postConfigure = (old.postConfigure or "") + ''
            find . -name "*.ninja" -exec sed -i 's/-O3/-O2/g' {} +
          '';
        });

        # userborn's xcrypt-sys uses bindgen as a library. bindgen passes
        # --target=$TARGET (gnuelfv2) to libclang first, so BINDGEN_EXTRA_CLANG_ARGS
        # comes too late — libclang errors on the bad triple before reaching the
        # env args. Patch the vendored build.rs to inject .clang_arg() overrides
        # directly onto the Builder, where they win over bindgen's auto-target.
        userborn = prev.userborn.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            for bs in $(find "$NIX_BUILD_TOP" -path '*/xcrypt-sys-*/build.rs'); do
              substituteInPlace "$bs" \
                --replace-fail 'Builder::default()' \
                  'Builder::default().clang_arg("--target=powerpc64-unknown-linux-gnu").clang_arg("-mabi=elfv2")'
            done
          '';
        });

        # hickory-dns (0.26-alpha w/ h3-aws-lc-rs & https-aws-lc-rs features):
        # aws-lc-sys has no pregenerated bindings for ppc64 → must run
        # cmake + external bindgen-cli. bindgen reads TARGET=…-gnuelfv2 and
        # passes --target=powerpc64-unknown-linux-gnuelfv2 to libclang, which
        # rejects `elfv2` as an invalid version component in the triple.
        # There's no env var that convinces bindgen otherwise (later
        # BINDGEN_EXTRA_CLANG_ARGS --target= flags don't win; libclang errors
        # on the first bad triple before reaching them).
        # Fix: shim bindgen with a shell wrapper that rewrites TARGET to the
        # plain gnu form and appends -mabi=elfv2 (so glibc's stubs.h picks
        # stubs-64-v2.h). The wrapper is placed in nativeBuildInputs AFTER
        # any real bindgen so it wins on PATH.
        hickory-dns = prev.hickory-dns.overrideAttrs (
          old:
          let
            bindgenShim = prev.buildPackages.writeShellScriptBin "bindgen" ''
              if [ -n "''${TARGET-}" ]; then
                export TARGET="''${TARGET//gnuelfv2/gnu}"
              fi
              export BINDGEN_EXTRA_CLANG_ARGS="''${BINDGEN_EXTRA_CLANG_ARGS:-} --target=powerpc64-unknown-linux-gnu -mabi=elfv2"
              exec ${prev.buildPackages.rust-bindgen}/bin/bindgen "$@"
            '';
          in
          {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              prev.buildPackages.cmake
              prev.buildPackages.rustPlatform.bindgenHook
              bindgenShim
            ];
            # aws-lc + jitterentropy CMakeLists set -Werror, and cc-rs passes
            # clang-only flags like -Wno-c11-extensions that gcc emits a note
            # about. With -Werror plus other real warnings (_FORTIFY_SOURCE
            # noise from glibc headers), gcc fails. Strip -Werror from every
            # aws-lc CMakeLists the vendor ships, including third_party.
            preBuild = (old.preBuild or "") + ''
              find "$NIX_BUILD_TOP" -path '*/aws-lc-sys-*/aws-lc/*' \
                \( -name CMakeLists.txt -o -name '*.cmake' \) \
                -print0 2>/dev/null | while IFS= read -r -d "" f; do
                chmod +w "$f" "$(dirname "$f")"
                sed -i -E 's/-Werror(=[^[:space:]"]+)?//g' "$f"
              done
            '';
          }
        );
        # Disabled test suites — fail or hang on ppc64
        nix = prev.nix.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
        git = prev.git.override {
          doInstallCheck = false;
          rustSupport = false;
        };
        coreutils = prev.coreutils.overrideAttrs (_: {
          doCheck = false;
        });
        coreutils-full = prev.coreutils-full.overrideAttrs (_: {
          doCheck = false;
        });
        findutils = prev.findutils.overrideAttrs (_: {
          doCheck = false;
        });
        byacc = prev.byacc.overrideAttrs (_: {
          doCheck = false;
        });
        bmake = prev.bmake.overrideAttrs (_: {
          doCheck = false;
        });
        gnugrep = prev.gnugrep.overrideAttrs (_: {
          doCheck = false;
        });

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
            filelock = pyprev.filelock.overrideAttrs (_: {
              doInstallCheck = false;
            });
            cryptography-vectors = pyprev.cryptography-vectors.overrideAttrs (_: {
              nativeBuildInputs = [ ];
              buildPhase = "mkdir -p $out $dist";
              installPhase = "true";
              dontUsePypaInstall = true;
            });
            cryptography = pyprev.cryptography.overrideAttrs (_: {
              doInstallCheck = false;
            });
            # jc: shell completion generation runs cross-compiled binary
            jc = pyprev.jc.overrideAttrs (_: {
              postInstall = "";
            });
            # numpy: test_limited_api spawns `meson compile` which fails cross
            numpy = pyprev.numpy.overrideAttrs (_: {
              doCheck = false;
              doInstallCheck = false;
            });
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

        # dbus: SUID + chown fail in user namespace; copy_data_for_tests.py fails in cross
        dbus = prev.dbus.overrideAttrs (old: {
          doCheck = false;
          postPatch = (old.postPatch or "") + ''
            sed -i -e 's/stat.S_ISUID | //' -e 's/os.chown/# os.chown/' meson_post_install.py
            # Remove copy_data_for_tests.py run_command — fails in cross/sandbox
            sed -i '/run_result.*copy_data_for_tests/,/^endif/d' test/data/meson.build
          '';
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.removeReferencesTo ];
          postFixup = (old.postFixup or "") + ''
            find $lib -type f \( -name '*.so*' -o -executable \) -exec remove-references-to -t $out {} + || true
          '';
        });

        # jemalloc: skip tests + drop GNU AutoGen dep. nixpkgs added `autogen`
        # to nativeBuildInputs because jemalloc has a script `autogen.sh`, but
        # that script is jemalloc's own bootstrap wrapper around autoconf — it
        # has nothing to do with GNU AutoGen (the template generator that pulls
        # guile). Dropping the dep cuts out the whole guile chain.
        jemalloc = prev.jemalloc.overrideAttrs (old: {
          doCheck = false;
          nativeBuildInputs = builtins.filter (x: (x.pname or "") != "autogen") (
            old.nativeBuildInputs or [ ]
          );
        });
        # libsndfile: skip tests. Keep autogen (GNU AutoGen) — libsndfile's
        # Makefile does invoke it to generate tests/*.c from .def files via
        # BUILT_SOURCES; removing it breaks `make all`.
        libsndfile = prev.libsndfile.overrideAttrs (_: {
          doCheck = false;
        });

        # newt: configure picks up host Debian tclConfig.sh causing segfault
        newt = prev.newt.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [ "--without-tcl" ];
        });

        # uutils-coreutils needs two ppc64-cross fixes:
        # 1. Vendored libc crate hardcodes link_name = "cfsetispeed@GLIBC_2.3"
        #    (and the three sibling cf*speed funcs) under
        #    cfg(target_arch="powerpc64", target_endian="big", target_env="gnu").
        #    That version suffix only exists in ppc64 ELFv1 glibc; our ELFv2
        #    glibc exports modern unversioned symbols. Strip @GLIBC_2.3 from
        #    every link_name so callers bind to the default symbol.
        # 2. install-manpages/install-completions depend on build-uudoc, which
        #    the Makefile deliberately builds for the HOST (unset
        #    CARGO_BUILD_TARGET). But nixpkgs cross only unsets CARGO_BUILD_TARGET
        #    — it leaves $CC pointing at the ppc64 cross-gcc. The blake3 dep's
        #    cc-rs then feeds x86_64 .S files to ppc64 gcc and fails. Skip both
        #    install steps; man pages and completions aren't worth the host-tool
        #    dance for a server.
        uutils-coreutils = prev.uutils-coreutils.overrideAttrs (old: {
          makeFlags = (old.makeFlags or [ ]) ++ [
            "MANPAGES=n"
            "COMPLETIONS=n"
          ];
          preBuild = (old.preBuild or "") + ''
            for f in $(find "$NIX_BUILD_TOP" -path '*/libc-*/src/unix/mod.rs' 2>/dev/null); do
              chmod +w "$f" "$(dirname "$f")"
              sed -i 's|@GLIBC_2\.3"|"|g' "$f"
            done
          '';
        });

        # uv: vendored target-lexicon 0.13.5 doesn't know the gnuelfv2 environment
        # and panics at build time. Teach its FromStr impl to map gnuelfv2 onto
        # Gnu — build.rs include!s src/targets.rs so one patch fixes both.
        # The vendor tarball is extracted by cargoSetupHook in configurePhase
        # (sibling dir, not under $sourceRoot), so postPatch is too early.
        # Use preBuild and make the vendored files writable before sed.
        uv = prev.uv.overrideAttrs (old: {
          preBuild = (old.preBuild or "") + ''
            for f in $(find "$NIX_BUILD_TOP" -path '*/target-lexicon-*/src/targets.rs' 2>/dev/null); do
              chmod +w "$f" "$(dirname "$f")"
              substituteInPlace "$f" \
                --replace-fail '"gnu" => Gnu,' '"gnu" | "gnuelfv2" => Gnu,'
            done
          '';
        });

        # bcachefs-tools: bch_bindgen/build.rs runs TWO bindgen builders.
        # (1) libbcachefs — explicitly passes .clang_arg("--target={target}").
        # (2) keyutils — passes no --target, but libclang still ends up with
        #     gnuelfv2 (nixpkgs cc-wrapper propagates TARGET via env).
        # Both fail because clang parses the triple and rejects the `elfv2`
        # version component. Fix: rewrite the `let target` binding so every
        # downstream format!() uses a valid triple, add -mabi=elfv2 to the
        # libbcachefs call, and inject --target + -mabi=elfv2 into the
        # keyutils builder chain before .generate().
        bcachefs-tools = (prev.bcachefs-tools.overrideAttrs (old: {
          version = "1.38.0";
          src = prev.fetchFromGitHub {
            owner = "koverstreet";
            repo = "bcachefs-tools";
            rev = "v1.38.0";
            hash = "sha256-ARSrlQozhefNV4K75aiaKxgfKIkE9mPrDksDhuvXfA4=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            src = prev.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs-tools";
              rev = "v1.38.0";
              hash = "sha256-ARSrlQozhefNV4K75aiaKxgfKIkE9mPrDksDhuvXfA4=";
            };
            hash = "sha256-dtGRtJxsVvltjPdMl0KZMaAqnNppwGCtL/XnYbc1PyQ=";
          };
          postPatch = (old.postPatch or "") + ''
            substituteInPlace bch_bindgen/build.rs \
              --replace-fail \
                'let target = std::env::var("TARGET").unwrap();' \
                'let target = std::env::var("TARGET").unwrap().replace("gnuelfv2", "gnu");' \
              --replace-fail \
                '.clang_arg(format!("--target={}", target))' \
                '.clang_arg(format!("--target={}", target)).clang_arg("-mabi=elfv2")' \
              --replace-fail \
                '.map(|p| format!("-I{}", p.display())),' \
                '.map(|p| format!("-I{}", p.display())).chain([format!("--target={}", target), "-mabi=elfv2".to_string()]),'
          '';
        }));

        # g-ir-scanner runs target binaries via qemu-user, but nixpkgs'
        # qemu-ppc64 can't load ppc64be glib ("ELF file data encoding not
        # little-endian"). Every GObject library passes `withIntrospection` as an
        # override arg — use `.override` (not overrideAttrs), which properly
        # strips gobject-introspection from nativeBuildInputs, drops devdoc,
        # skips the .gir/typelib outputs, and disables gtk-doc.
        libgudev = prev.libgudev.override { withIntrospection = false; };
        json-glib = prev.json-glib.override { withIntrospection = false; };
        gusb = prev.gusb.override { withIntrospection = false; };
        harfbuzz = prev.harfbuzz.override { withIntrospection = false; };
        pango = prev.pango.override { withIntrospection = false; };
        gdk-pixbuf = prev.gdk-pixbuf.override { withIntrospection = false; };
        libxmlb = prev.libxmlb.override { withIntrospection = false; };

        # lldb: standalone cross-compile requires a native LLVM build alongside,
        # which nixpkgs doesn't set up. Not needed on a server.
        lldb = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
          lib = prev.emptyDirectory;
        };

        # protobuf: tests fail (cross-compiled ppc64 AND native build-platform)
        protobuf = prev.protobuf.overrideAttrs (old: {
          doCheck = false;
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-Dprotobuf_BUILD_TESTS=OFF" ];
        });

        # zfs bash-completion path fix
        zfs = prev.zfs.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [
            "--with-bash-completiondir=${placeholder "out"}/share/bash-completion/completions"
          ];
        });

        # LLVM: three fixes applied to llvm_21, libllvm, llvmPackages_21.{llvm,libllvm}:
        # 1. GCC 15 ICE in cprop_hardreg at -O3 on ppc64 (AMDGPUAsanInstrumentation.cpp)
        # 2. GCC 15 also segfaults in std::variant header at -O2 on x86 (X86FastTileConfig.cpp).
        #    Use gcc14Stdenv — GCC 14 is stable and has been tested for LLVM 21.
        # 3. Cross-compile postInstall expects NATIVE/bin/llvm-config but nixpkgs
        #    passes pre-built LLVM_TABLEGEN so the NATIVE sub-build never runs.
        #    Provide it as a symlink to pkgsBuildBuild's llvm-config.
        llvm_21 = (prev.llvm_21.override { stdenv = prev.gcc14Stdenv; }).overrideAttrs (old: {
          postConfigure = (old.postConfigure or "") + ''
            sed -i 's/-O3/-O2/g' CMakeCache.txt
          '';
          preInstall =
            (old.preInstall or "")
            + lib.optionalString (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) ''
              mkdir -p NATIVE/bin
              ln -sf ${final.pkgsBuildBuild.llvmPackages_21.llvm.dev}/bin/llvm-config NATIVE/bin/llvm-config
            '';
        });
        libllvm = (prev.libllvm.override { stdenv = prev.gcc14Stdenv; }).overrideAttrs (old: {
          postConfigure = (old.postConfigure or "") + ''
            sed -i 's/-O3/-O2/g' CMakeCache.txt
          '';
          preInstall =
            (old.preInstall or "")
            + lib.optionalString (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) ''
              mkdir -p NATIVE/bin
              ln -sf ${final.pkgsBuildBuild.llvmPackages_21.libllvm.dev}/bin/llvm-config NATIVE/bin/llvm-config
            '';
        });
        llvmPackages_21 = prev.llvmPackages_21 // {
          llvm = (prev.llvmPackages_21.llvm.override { stdenv = prev.gcc14Stdenv; }).overrideAttrs (old: {
            postConfigure = (old.postConfigure or "") + ''
              sed -i 's/-O3/-O2/g' CMakeCache.txt
            '';
            preInstall =
              (old.preInstall or "")
              + lib.optionalString (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) ''
                mkdir -p NATIVE/bin
                ln -sf ${final.pkgsBuildBuild.llvmPackages_21.llvm.dev}/bin/llvm-config NATIVE/bin/llvm-config
              '';
          });
          libllvm =
            (prev.llvmPackages_21.libllvm.override { stdenv = prev.gcc14Stdenv; }).overrideAttrs
              (old: {
                postConfigure = (old.postConfigure or "") + ''
                  sed -i 's/-O3/-O2/g' CMakeCache.txt
                '';
                preInstall =
                  (old.preInstall or "")
                  + lib.optionalString (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) ''
                    mkdir -p NATIVE/bin
                    ln -sf ${final.pkgsBuildBuild.llvmPackages_21.libllvm.dev}/bin/llvm-config NATIVE/bin/llvm-config
                  '';
              });
          # clang-21 (libclang/clang-unwrapped) also needs gcc14Stdenv: GCC 15's
          # stricter -Wmaybe-uninitialized triggers -Werror in clang's CMake build on
          # ASTContext.cpp, LiteralSupport.cpp.
          libclang = prev.llvmPackages_21.libclang.override {
            stdenv = prev.gcc14Stdenv;
          };
        };

        # groff: broken PDF in doc output
        groff = prev.groff.overrideAttrs (_: {
          postFixup = "rm -f $doc/share/doc/groff-1.23.0/pdf/mom-pdf.pdf";
        });

        # Meta C++ stack: folly uses try_run() incompatible with cross-compilation;
        # fizz/wangle/fb303/edencommon/fbthrift/mvfst all depend on folly
        folly = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        fizz = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        wangle = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        fb303 = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        fbthrift = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        edencommon = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        mvfst = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };

        # curl-impersonate: bundles boringssl with no ppc64 support
        curl-impersonate = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };

        # Unnecessary packages for headless ppc64 server
        yt-dlp = prev.emptyDirectory;
        watchman = prev.emptyDirectory;

        # valgrind: ppc64be asm unconditionally uses ELFv1 .opd sections.
        # Patch adds _CALL_ELF == 2 guards (same pattern ppc64le already uses).
        valgrind = prev.valgrind.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./patches/valgrind-ppc64be-elfv2.patch ];
        });

        # ppc64 isn't EFI — stub out EFI packages
        gnu-efi = prev.emptyDirectory // {
          dev = prev.emptyDirectory;
        };
        fwupd-efi = prev.emptyDirectory;

        # deno doesn't support ppc64
        deno = prev.emptyDirectory // {
          meta = {
            mainProgram = "deno";
          };
        };

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

        # Kernel preFixup calls bare `strip` (not $STRIP), which resolves to
        # host x86 binutils. x86 strip has no ppc64 BFD targets and fails on
        # the BE vmlinux. Suppress preFixup; modules are still stripped via
        # kbuild's INSTALL_MOD_STRIP=1 which uses the target strip from makeFlags.
        linuxPackages_latest = prev.linuxPackages_latest.extend (
          _: kprev: {
            kernel = kprev.kernel.overrideAttrs (_: {
              preFixup = "";
            });
          }
        );
      })
    ];

    # Disable ZFS (broken on ppc64 ELFv2)
    boot.supportedFilesystems = lib.mkForce [ "bcachefs" ];
    boot.zfs.forceImportAll = lib.mkForce false;
    boot.zfs.forceImportRoot = lib.mkForce false;

    # Disable polkit (broken in cross-compilation)
    security.polkit.enable = lib.mkForce false;

    # Disable udisks (enabled by default, pulls huge desktop dep chain)
    services.udisks2.enable = lib.mkForce false;

    security.sudo.enable = lib.mkDefault true;

    # Suppress extra dependencies the ISO module adds
    system.extraDependencies = lib.mkForce [ ];
  };
}
