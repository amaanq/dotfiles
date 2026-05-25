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

    # pypy2.7-setuptools trips the security gate at eval; not in the closure.
    nixpkgs.config.permittedInsecurePackages = [
      "pypy2.7-setuptools-44.0.0"
      "pypy2.7-pip-20.3.4"
    ];

    # GCC 15 miscompiles / ICEs on BATMAN_ADV, GFS2_FS, KSM on ppc64 cross.
    boot.kernelPatches = [
      {
        name = "ppc64-disable-useless-drivers";
        patch = null;
        extraConfig = ''
          BATMAN_ADV n
          GFS2_FS n
          KSM n
        '';
      }
      {
        # pahole 1.31 segfaults on some ppc64 kernel modules; skip BTF for those.
        name = "pahole-btf-crash-tolerance";
        patch = ./patches/kernel-btf-pahole-crashtolerance.patch;
      }
    ];

    nixpkgs.overlays = [
      (
        final: prev:
        let
          # Helper for -sys crates that bundle a C library via cc-rs/cmake.
          # Forces pkg-config against the build-host system library so the
          # cross toolchain doesn't get fed build-host build scripts.
          mkSysCrateOverride =
            {
              pkg,
              env,
              nativeLib,
              hostLib,
            }:
            pkg.overrideAttrs (old: {
              env =
                (old.env or { })
                // env
                // {
                  PKG_CONFIG_ALLOW_CROSS = "1";
                };
              buildInputs = (old.buildInputs or [ ]) ++ [ hostLib ];
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nativeLib ];
              preBuild =
                (old.preBuild or "")
                + ''
                  export HOST_PKG_CONFIG_PATH="${nativeLib.dev}/lib/pkgconfig''${HOST_PKG_CONFIG_PATH:+:$HOST_PKG_CONFIG_PATH}"
                ''
                + cargoCcRouterPreBuild
                + pkgConfigRouterPreBuild;
            });

          # cargo exposes TARGET to every build script including build-host
          # artifacts in proc-macro chains. Route cc/cxx by OUT_DIR so
          # build-host scripts hit the build-host compiler, target scripts
          # the cross compiler. binutils 2.46 hard-fails on wrong EM type.
          targetCc = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";
          targetCxx = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}c++";
          buildCc = "${prev.buildPackages.stdenv.cc}/bin/cc";
          buildCxx = "${prev.buildPackages.stdenv.cc}/bin/c++";
          cargoCcRouter = prev.buildPackages.writeShellScriptBin "cargo-cc-router" ''
            case "$OUT_DIR" in
              *"/powerpc64-"*) exec ${targetCc} "$@" ;;
              *) exec ${buildCc} "$@" ;;
            esac
          '';
          cargoCxxRouter = prev.buildPackages.writeShellScriptBin "cargo-cxx-router" ''
            case "$OUT_DIR" in
              *"/powerpc64-"*) exec ${targetCxx} "$@" ;;
              *) exec ${buildCxx} "$@" ;;
            esac
          '';
          cargoCcRouterPreBuild = ''
            export CC=${cargoCcRouter}/bin/cargo-cc-router
            export CXX=${cargoCxxRouter}/bin/cargo-cxx-router
          '';

          # pkg-config-rs ignores HOST_PKG_CONFIG_PATH under cross; route
          # build-host invocations through pkgsBuildBuild's plain pkg-config.
          nativePkgConfig = prev.pkgsBuildBuild.pkg-config;
          pkgConfigRouter = prev.buildPackages.writeShellScriptBin "pkg-config" ''
            case "$OUT_DIR" in
              *"/powerpc64-"*)
                exec ${nativePkgConfig}/bin/pkg-config "$@"
                ;;
              *)
                if [ -n "$HOST_PKG_CONFIG_PATH" ]; then
                  PKG_CONFIG_PATH="$HOST_PKG_CONFIG_PATH" \
                    exec ${nativePkgConfig}/bin/pkg-config "$@"
                else
                  exec ${nativePkgConfig}/bin/pkg-config "$@"
                fi
                ;;
            esac
          '';
          pkgConfigRouterPreBuild = ''
            export PKG_CONFIG=${pkgConfigRouter}/bin/pkg-config
          '';
          targetIsPpc64 = prev.stdenv.targetPlatform.isPower64 or false;
        in
        {
          # ppc64 BE uses the ELFv2 ABI, but stock rustc only ships the ELFv1
          # powerpc64-unknown-linux-gnu target. Patch is applied unconditionally
          # because the cross rust bootstrap uses `--set=build.rustc=` pointing
          # at pkgsBuildBuild.rustc (native x86_64, target=x86_64) — and THAT
          # rust is what compiles stdlib for ppc64-elfv2 during the cross build.
          # Without the patch on pkgsBuildBuild.rust, --print=file-names fails
          # with "could not find specification for target". Costs one native
          # rust rebuild; cheaper than a duplicate LLVM.
          rust_1_95 = prev.rust_1_95 // {
            packages = prev.rust_1_95.packages // {
              stable = prev.rust_1_95.packages.stable.overrideScope (
                _: rprev: {
                  rustc-unwrapped = rprev.rustc-unwrapped.overrideAttrs (old: {
                    patches = (old.patches or [ ]) ++ [
                      ./patches/rust-ppc64-elfv2-target.patch
                      ./patches/rust-bootstrap-symlink-over-dir.patch
                    ];
                    # Doc generation runs error_index_generator, a ppc64 BE
                    # binary; under qemu it can't load the little-endian
                    # libLLVM.so.21.1. Stack bump avoids stage1 symbol-table
                    # overflow. Only when target=ppc64; native rust skips both.
                    configureFlags =
                      (old.configureFlags or [ ])
                      ++ lib.optional targetIsPpc64 "--set=build.docs=false";
                    env =
                      (old.env or { })
                      // lib.optionalAttrs targetIsPpc64 { RUST_MIN_STACK = "16777216"; };
                  });
                }
              );
            };
          };
        }
        // lib.optionalAttrs (prev.stdenv.hostPlatform.isPower64 or false) {
          # GCC 15.2 ICEs at -O2 in ipa-cp.cc / ipa-icf-gimple.cc when building
          # the ppc64 cross-gcc; pragma those files down to -O1.
          gcc-unwrapped = prev.gcc-unwrapped.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              for f in gcc/ipa-cp.cc gcc/ipa-icf-gimple.cc; do
                if [ -f "$f" ] && ! grep -q 'pragma GCC optimize' "$f"; then
                  sed -i '1i #pragma GCC optimize("-O1")' "$f"
                fi
              done
            '';
          });

          # Non-EFI grub can't build for ppc64 ELFv2
          grub2 = prev.grub2.overrideAttrs (_: {
            meta = { };
          });
          grub2_efi = prev.grub2.overrideAttrs (_: {
            meta = { };
          });

          # dmi_memory_id is x86-only; nixpkgs udev.nix still adds it to
          # initrd storePaths. Drop a no-op stub so make-initrd-ng resolves.
          systemd = prev.systemd.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Doptimization=2" ];
            postFixup = (old.postFixup or "") + ''
              if [ -d "$out/lib/udev" ] && [ ! -e "$out/lib/udev/dmi_memory_id" ]; then
                chmod +w "$out/lib/udev"
                printf '#!/bin/sh\nexit 0\n' > "$out/lib/udev/dmi_memory_id"
                chmod 555 "$out/lib/udev/dmi_memory_id"
                chmod -w "$out/lib/udev"
              fi
            '';
          });
          systemdMinimal = prev.systemdMinimal.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Doptimization=2" ];
            postFixup = (old.postFixup or "") + ''
              if [ -d "$out/lib/udev" ] && [ ! -e "$out/lib/udev/dmi_memory_id" ]; then
                chmod +w "$out/lib/udev"
                printf '#!/bin/sh\nexit 0\n' > "$out/lib/udev/dmi_memory_id"
                chmod 555 "$out/lib/udev/dmi_memory_id"
                chmod -w "$out/lib/udev"
              fi
            '';
          });

          # openssl asm broken on BE. Its test suite is also unreliable here:
          # 70-test_quic_multistream.t is a known-flaky timing race (openssl
          # #26949, #27356) that trips on slow/loaded machines, and the suite
          # burns ~56 min on this cacheless cross target, so skip it like the
          # other BE test suites.
          openssl = prev.openssl.overrideAttrs (old: {
            configureFlags = (old.configureFlags or [ ]) ++ [ "no-asm" ];
            doCheck = false;
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

          # aws-lc-sys runs bindgen with TARGET=…-gnuelfv2 which libclang
          # rejects. Shim bindgen with a wrapper that rewrites the triple
          # and adds -mabi=elfv2.
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

          # Alien-Build's devdoc output fails under cross perl; stub moreutils
          # (its withPackages chain pulls Alien-Build).
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

          # jemalloc's autogen.sh isn't GNU AutoGen; drop the dep to cut guile.
          jemalloc = prev.jemalloc.overrideAttrs (old: {
            doCheck = false;
            nativeBuildInputs = builtins.filter (x: (x.pname or "") != "autogen") (
              old.nativeBuildInputs or [ ]
            );
          });
          # libsndfile genuinely uses GNU AutoGen via BUILT_SOURCES; keep it.
          libsndfile = prev.libsndfile.overrideAttrs (_: {
            doCheck = false;
          });

          # newt: configure picks up host Debian tclConfig.sh causing segfault
          newt = prev.newt.overrideAttrs (old: {
            configureFlags = (old.configureFlags or [ ]) ++ [ "--without-tcl" ];
          });

          # libc crate hardcodes cf*speed@GLIBC_2.3 for ppc64; ELFv2 glibc
          # only exports unversioned, so strip the suffix. Also skip manpage
          # and completion install (build-uudoc trips the cc-rs cross bug).
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
          # BLKGETSIZE64 ioctl is hardcoded to the asm-generic encoding
          # (0x80081272). PowerPC, MIPS, SPARC use the 3-bit dir / 13-bit size
          # layout and want 0x40081272 instead — without this, mkfs sees ppc64
          # block devices as 0 bytes and refuses to format. Still hardcoded
          # upstream as of 1.38.3 (koverstreet/bcachefs-tools); PR pending.
          # The postPatch fixes the elfv2 triple bindgen otherwise rejects.
          bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./patches/bcachefs-tools-blkgetsize64-per-arch.patch
            ];
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
          });

          # onig_sys's bundled cmake build emits ppc64 .o into the build-host
          # archive under cross; binutils 2.46 then refuses the link. Force
          # pkg-config against the system oniguruma instead.
          xh = mkSysCrateOverride {
            pkg = prev.xh;
            env.RUSTONIG_DYNAMIC_LIBONIG = "1";
            nativeLib = prev.buildPackages.oniguruma;
            hostLib = prev.oniguruma;
          };

          # atuin needs libsqlite3-sys to find system sqlite; patch its
          # build script to inject the build-host link search + PKG_CONFIG_PATH.
          atuin =
            (mkSysCrateOverride {
              pkg = prev.atuin;
              env.LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";
              nativeLib = prev.buildPackages.sqlite;
              hostLib = prev.sqlite;
            }).overrideAttrs
              (old: {
                preBuild = (old.preBuild or "") + ''
                  export HOST_SQLITE3_LIB_DIR="${prev.buildPackages.sqlite.out}/lib"
                  for f in $(find "$NIX_BUILD_TOP" -path '*/libsqlite3-sys-*/build.rs' -type f 2>/dev/null); do
                    chmod +w "$f" "$(dirname "$f")"
                    substituteInPlace "$f" \
                      --replace-fail \
                        'let link_lib = lib_name();' \
                        'let link_lib = lib_name(); if env::var("OUT_DIR").map(|d| !d.contains("/powerpc64-")).unwrap_or(false) { if let Ok(dir) = env::var("HOST_SQLITE3_LIB_DIR") { println!("cargo:rustc-link-search=native={}", dir); } if let Ok(path) = env::var("HOST_PKG_CONFIG_PATH") { unsafe { env::set_var("PKG_CONFIG_PATH", path); } } }'
                  done
                '';
              });

          # rquickjs-sys's build.rs feeds clang the elfv2 target triple it
          # rejects. Strip elfv2 from the triple and inject -mabi=elfv2.
          # The patch is conditional on OUT_DIR/TARGET so the build-host
          # branch (proc-macro chain) doesn't mismatch x86_64 sysroot headers.
          tree-sitter = prev.tree-sitter.overrideAttrs (old: {
            preBuild = (old.preBuild or "") + ''
              # When rquickjs-sys is built as a build-host artifact (proc-macro
              # graph), both bindgen AND cc-rs see cargo's TARGET=ppc64 (cargo
              # bug for build-host deps in proc-macro chains). bindgen reads
              # the ppc64 sysroot via BINDGEN_EXTRA_CLANG_ARGS; cc-rs picks the
              # cross gcc and compiles quickjs.c to ppc64 .o, which then gets
              # linked into the x86_64 .rlib and binutils 2.46 rejects it.
              # Patch build.rs to: detect build-host OUT_DIR, force TARGET to
              # HOST so cc-rs picks build-host gcc, swap BINDGEN_EXTRA_CLANG_ARGS
              # to build-host glibc+clang headers.
              export BINDGEN_NATIVE_CLANG_ARGS="-isystem ${prev.pkgsBuildBuild.stdenv.cc.libc_dev}/include -isystem ${prev.pkgsBuildBuild.llvmPackages.libclang.lib}/lib/clang/${lib.versions.major prev.pkgsBuildBuild.llvmPackages.libclang.version}/include"
              export NATIVE_HOST_CC="${prev.pkgsBuildBuild.stdenv.cc}/bin/cc"
              export NATIVE_HOST_CXX="${prev.pkgsBuildBuild.stdenv.cc}/bin/c++"
              export NATIVE_HOST_AR="${prev.pkgsBuildBuild.stdenv.cc.bintools}/bin/ar"
              echo "[rquickjs-patch] NIX_BUILD_TOP=$NIX_BUILD_TOP cargoDepsCopy=''${cargoDepsCopy:-UNSET}"
              echo "[rquickjs-patch] BINDGEN_NATIVE_CLANG_ARGS=$BINDGEN_NATIVE_CLANG_ARGS"
              echo "[rquickjs-patch] NATIVE_HOST_CC=$NATIVE_HOST_CC"
              shopt -s nullglob globstar
              patched_any=0
              for f in "$NIX_BUILD_TOP"/**/rquickjs-sys-*/build.rs; do
                [ -f "$f" ] || continue
                chmod +w "$f" "$(dirname "$f")"
                echo "[rquickjs-patch] patching $f"
                substituteInPlace "$f" \
                  --replace-fail \
                    'let mut target = env::var("TARGET").unwrap();' \
                    'let mut target = env::var("TARGET").unwrap(); { let host = env::var("HOST").unwrap_or_default(); let out_dir_env = env::var("OUT_DIR").unwrap_or_default(); let bindgen_args = env::var("BINDGEN_EXTRA_CLANG_ARGS").unwrap_or_default(); let native_args = env::var("BINDGEN_NATIVE_CLANG_ARGS").unwrap_or_default(); let want_native = (!target.starts_with("powerpc64") && bindgen_args.contains("gnuabielfv2")) || (!out_dir_env.contains("/powerpc64-") && target != host); if want_native { unsafe { env::set_var("BINDGEN_EXTRA_CLANG_ARGS", &native_args); env::set_var("TARGET", &host); if let Ok(cc) = env::var("NATIVE_HOST_CC") { env::set_var("CC", &cc); env::set_var(format!("CC_{}", host.replace("-", "_")), &cc); } if let Ok(cxx) = env::var("NATIVE_HOST_CXX") { env::set_var("CXX", &cxx); env::set_var(format!("CXX_{}", host.replace("-", "_")), &cxx); } if let Ok(ar) = env::var("NATIVE_HOST_AR") { env::set_var("AR", &ar); env::set_var(format!("AR_{}", host.replace("-", "_")), &ar); } env::remove_var("CFLAGS"); env::remove_var("CXXFLAGS"); env::remove_var(format!("CFLAGS_{}", target.replace("-", "_"))); env::remove_var(format!("CXXFLAGS_{}", target.replace("-", "_"))); } target = host.clone(); } } target = target.replace("gnuelfv2", "gnu"); eprintln!("[rquickjs-patch-runtime] target={} OUT_DIR={} CC={} BINDGEN_EXTRA_CLANG_ARGS={}", target, env::var("OUT_DIR").unwrap_or_default(), env::var("CC").unwrap_or_default(), env::var("BINDGEN_EXTRA_CLANG_ARGS").unwrap_or_default());' \
                  --replace-fail \
                    'let mut cflags = vec![format!("--target={}", target)];' \
                    'let mut cflags = vec![format!("--target={}", target)]; if target.starts_with("powerpc64") { cflags.push("-mabi=elfv2".to_string()); } if let Ok(extra) = env::var("BINDGEN_EXTRA_CLANG_ARGS") { for a in extra.split_whitespace() { cflags.push(a.to_string()); } } eprintln!("[rquickjs-patch-runtime] cflags={:?}", cflags);'
                patched_any=1
              done
              if [ "$patched_any" = 0 ]; then
                echo "[rquickjs-patch] WARNING: no rquickjs-sys/build.rs matched!"
              fi
            '';
          });

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
        }
      )
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
