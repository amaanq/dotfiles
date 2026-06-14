# mips64 Big Endian (n64) package fixes for cross-compilation.
# Auto-imported on every linux host; gated on isMips so it's a no-op unless the
# host is a cross-compiled mips64 target (the EdgeRouter Infinity, varve).
{
  config,
  lib,
  inputs,
  ...
}:
let
  isMips = config.nixpkgs.hostPlatform.isMips or false;

  # Statically-linked qemu-user from the overlay-free host nixpkgs. The g-ir
  # scanner runs cross binaries under qemu; a qemu-user pulled through this
  # eval's overlays would cycle back through glib -> gobject-introspection (the
  # very package being patched), so it must come from outside any overlay.
  hostQemuStatic = inputs.nixpkgs.legacyPackages.x86_64-linux.pkgsStatic.qemu-user;
in
{
  config = lib.mkIf isMips {
    nixpkgs.config.allowUnsupportedSystem = true;

    # Out-of-tree MIPS module builds fail against the stock kernel.dev: it
    # prunes arch/mips/Kbuild.platforms + the per-platform Platform files (which
    # arch/mips/Makefile includes for load-y) and the read-only objtree rejects
    # cc-option probes. Stage a writable copy, restore the pruned files from the
    # source tarball, and build against that. Only takes effect when a host
    # enables bcachefs; mkForce beats the bcachefs module's own default.
    boot.bcachefs.modulePackage = lib.mkForce (
      let
        k = config.boot.kernelPackages.kernel;
        kbuild = "lib/modules/${k.modDirVersion}/build";
        ksrcsub = "lib/modules/${k.modDirVersion}/source";
        base = config.boot.kernelPackages.callPackage config.boot.bcachefs.package.kernelModule { };
      in
      base.overrideAttrs (old: {
        preBuild = (old.preBuild or "") + ''
          kdev="$NIX_BUILD_TOP/kdev"
          cp -a ${k.dev} "$kdev"
          chmod -R u+w "$kdev"
          grep -rlIF '${k.dev}' "$kdev" | xargs -r sed -i "s|${k.dev}|$kdev|g"
          ktar="$(mktemp -d)"
          tar -xf ${k.src} -C "$ktar" --strip-components=1
          mips="$kdev/${ksrcsub}/arch/mips"
          cp "$ktar/arch/mips/Kbuild.platforms" "$mips/"
          for p in "$ktar"/arch/mips/*/Platform; do
            d="$mips/$(basename "$(dirname "$p")")"
            mkdir -p "$d"
            cp "$p" "$d/"
          done
          makeFlags+=( "KDIR=$kdev/${kbuild}" "KBUILD_OUTPUT=$kdev/${kbuild}" )
        '';
        installPhase = ''
          runHook preInstall
          make -C "$NIX_BUILD_TOP/kdev/${kbuild}" M="$(pwd)" modules_install \
            ''${makeFlags[@]} ''${installFlags[@]} "KDIR=$NIX_BUILD_TOP/kdev/${kbuild}"
          runHook postInstall
        '';
      })
    );

    nixpkgs.overlays = [
      (
        final: prev:
        let
          # Rust crates with cc-rs build scripts (blake3, onig_sys, ...) compile
          # host-side artifacts but pick up the cross mips64 `CC`, so cc-rs feeds
          # x86 flags (`-m64`) and asm to the mips gcc and fails. Point cc-rs at
          # the native cc for the build triple so host artifacts use x86 gcc.
          buildTriple = prev.lib.replaceStrings [ "-" ] [ "_" ] prev.stdenv.buildPlatform.config;
          useBuildCc =
            pkg:
            pkg.overrideAttrs (old: {
              env = (old.env or { }) // {
                "CC_${buildTriple}" = "${final.pkgsBuildBuild.stdenv.cc}/bin/cc";
                "CXX_${buildTriple}" = "${final.pkgsBuildBuild.stdenv.cc}/bin/c++";
              };
            });
        in
        {
          # No MIPS bootloader on this box (U-Boot TFTP-loads the kernel); the
          # minimal profile otherwise pulls grub unconditionally.
          grub2 = prev.emptyDirectory;
          grub2_efi = prev.emptyDirectory;

          # systemd-boot has no MIPS target and udevadm verify segfaults under
          # QEMU; drop every host-firmware feature this router has no use for.
          systemd = (
            (prev.systemd.override {
              withBootloader = false;
              withUkify = false;
              withTpm2Tss = false;
              withFido2 = false;
              withLibBPF = false;
            }).overrideAttrs
              (old: {
                doInstallCheck = false;
                # nixos' initrd udev storePaths expects lib/udev/dmi_memory_id on
                # mips (the v259 meson arch list), but the 260+ mips64 build no
                # longer produces it; ship a no-op so the initrd copy succeeds.
                postFixup = (old.postFixup or "") + /* sh */ ''
                  if [ -d "$out/lib/udev" ] && [ ! -e "$out/lib/udev/dmi_memory_id" ]; then
                    chmod +w "$out/lib/udev"
                    printf '#!/bin/sh\nexit 0\n' > "$out/lib/udev/dmi_memory_id"
                    chmod 555 "$out/lib/udev/dmi_memory_id"
                    chmod -w "$out/lib/udev"
                  fi
                '';
              })
          );

          # mips64 glibc's libc.so.6 has a PT_INTERP padded past the string
          # (p_filesz 104 vs strlen+1 100); goblin keeps the padding, and the
          # NUL bytes crash the dependency walk ("file name contained an
          # unexpected NUL byte").
          makeInitrdNGTool = prev.makeInitrdNGTool.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/main.rs --replace-fail \
                'if let Some(interp) = elf.interpreter {' \
                'if let Some(interp) = elf.interpreter.map(|i| i.trim_end_matches(char::from(0))) {'
            '';
          });

          # LibreSSL has no MIPS64 AES assembly.
          libressl = prev.libressl.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [
              "-DENABLE_ASM=OFF"
              "-DASM=OFF"
            ];
          });

          # n64 ABI closure tests fail under QEMU.
          libffi = prev.libffi.overrideAttrs { doCheck = false; };

          # jemalloc's autogen.sh pulls GNU AutoGen (-> guile); use autoreconfHook.
          jemalloc = prev.jemalloc.overrideAttrs (old: {
            nativeBuildInputs =
              builtins.filter (d: (d.pname or d.name or "") != "autogen") (old.nativeBuildInputs or [ ])
              ++ [ prev.autoreconfHook ];
            configureScript = "./configure";
          });

          onetbb = prev.onetbb.overrideAttrs { doCheck = false; };
          openssl = prev.openssl.overrideAttrs { doCheck = false; };
          # coreutils' test suite is filesystem/locale-sensitive and fails under
          # the cross/QEMU check.
          coreutils = prev.coreutils.overrideAttrs { doCheck = false; };
          coreutils-full = prev.coreutils-full.overrideAttrs { doCheck = false; };

          # uutils' onig_sys/blake3 cc-rs crates build both a host doc tool and
          # the target binaries; the build-cc split lets each compile its bundled
          # C with the right compiler.
          uutils-coreutils-noprefix = useBuildCc prev.uutils-coreutils-noprefix;
          atuin = useBuildCc prev.atuin;
          xh = useBuildCc prev.xh;
          git = prev.git.override { doInstallCheck = false; };
          gnutls = prev.gnutls.overrideAttrs { doCheck = false; };
          mercurial = prev.mercurial.overrideAttrs { doCheck = false; };
          libnvme = prev.libnvme.overrideAttrs { doCheck = false; };
          libical = prev.libical.overrideAttrs { doInstallCheck = false; };
          umockdev = prev.umockdev.overrideAttrs { doCheck = false; };

          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_: pyPrev: {
              pytest-xdist = pyPrev.pytest-xdist.overrideAttrs {
                doCheck = false;
                doInstallCheck = false;
              };
            })
          ];

          python3 = prev.python3.override {
            packageOverrides = _: pyPrev: {
              pygobject3 = pyPrev.pygobject3.overrideAttrs (old: {
                mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dtests=false" ];
                postPatch = (old.postPatch or "") + ''
                  rm -rf subprojects/gobject-introspection-tests
                  mkdir -p subprojects/gobject-introspection-tests
                  echo "project('gobject-introspection-tests', 'c')" > subprojects/gobject-introspection-tests/meson.build
                '';
              });
            };
          };

          # g-ir-scanner-qemuwrapper exec's a dynamic qemu-user with
          # LD_LIBRARY_PATH pointing at mips64 BE .so files; the host x86_64
          # loader rejects the BE libs. Swap in the static qemu-user (binfmt's
          # own) so there's no host-side dlopen path to pollute. The wrapper is a
          # runCommand-style derivation, so the substitution must append to
          # buildCommand (postBuild/postFixup never fire).
          gobject-introspection = prev.gobject-introspection.overrideAttrs (old: {
            buildCommand = (old.buildCommand or "") + ''

              f="$dev/bin/g-ir-scanner-qemuwrapper"
              if [ -f "$f" ]; then
                sed -i -E \
                  "s|/nix/store/[a-z0-9]+-qemu-user-[0-9.]+|${hostQemuStatic}|g" \
                  "$f"
              fi
            '';
          });

          # g-ir-scanner cross builds fail under QEMU; disable introspection on
          # the whole modem/glib stack.
          libqrtr-glib = prev.libqrtr-glib.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];
          });
          libqmi = prev.libqmi.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];
          });
          libmbim = prev.libmbim.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];
          });
          modemmanager = prev.modemmanager.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];
          });
          libgudev = prev.libgudev.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [
              "-Dintrospection=disabled"
              "-Dvapi=disabled"
            ];
          });
          polkit = prev.polkit.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];
          });
          networkmanager = prev.networkmanager.overrideAttrs (old: {
            mesonFlags =
              (old.mesonFlags or [ ])
              ++ lib.optionals (prev.stdenv.hostPlatform != prev.stdenv.buildPlatform) [
                "-Dintrospection=false"
              ];
          });

          # writeShellApplication runs shellcheck in checkPhase, which on cross
          # mips64 drags in the whole GHC ecosystem just to lint activation
          # scripts. Lying about bootstrap availability empties shellcheckCommand.
          shellcheck-minimal =
            prev.runCommandLocal "shellcheck-minimal-stub"
              {
                meta.mainProgram = "shellcheck";
                passthru.compiler.bootstrapAvailable = false;
              }
              ''
                mkdir -p $out/bin
                cat > $out/bin/shellcheck <<'EOF'
                #!${prev.runtimeShell}
                exit 0
                EOF
                chmod +x $out/bin/shellcheck
              '';
        }
      )

      # nixpkgs' GOARCH table omits big-endian mips64, so the go derivation gets
      # GOARCH=null and every Go package fails to eval. Go supports GOARCH=mips64
      # natively; inject it on the go compiler (buildGoModule inherits GOARCH
      # from it). Gated on a mips64 target so native build-tool go keeps its arch.
      (
        _: prev:
        let
          fixGo =
            g:
            g.overrideAttrs (
              old:
              lib.optionalAttrs (prev.stdenv.targetPlatform.isMips64 or false) {
                env = old.env // {
                  GOARCH = "mips64";
                };
              }
            );
        in
        {
          go = fixGo prev.go;
        }
        // lib.optionalAttrs (prev ? go_1_24) { go_1_24 = fixGo prev.go_1_24; }
        // lib.optionalAttrs (prev ? go_1_25) { go_1_25 = fixGo prev.go_1_25; }
        // lib.optionalAttrs (prev ? go_1_26) { go_1_26 = fixGo prev.go_1_26; }
      )

      # bcachefs-tools' rust bindgenHook pulls a cross clang whose compiler-rt
      # fails to build on mips64 BE (false-positive -Wmaybe-uninitialized under
      # -Werror in the sanitizer interceptors). This clang only parses headers
      # for bindgen and links no runtimes, so build builtins only and drop
      # -Werror. The builtins' clear_cache.c emits rdhwr (mips r2), which the
      # mips3 baseline rejects, so bump the ISA just enough to assemble.
      (
        _: prev:
        let
          fixedLlvm = prev.llvmPackages_21.overrideScope (
            _: lprev: {
              compiler-rt = lprev.compiler-rt.overrideAttrs (o: {
                cmakeFlags = (o.cmakeFlags or [ ]) ++ [
                  "-DCOMPILER_RT_ENABLE_WERROR=OFF"
                  "-DLLVM_ENABLE_WERROR=OFF"
                  "-DCOMPILER_RT_BUILD_SANITIZERS=OFF"
                  "-DCOMPILER_RT_BUILD_MEMPROF=OFF"
                  "-DCOMPILER_RT_BUILD_XRAY=OFF"
                  "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF"
                  "-DCOMPILER_RT_BUILD_PROFILE=OFF"
                  "-DCOMPILER_RT_BUILD_GWP_ASAN=OFF"
                  "-DCOMPILER_RT_BUILD_ORC=OFF"
                  "-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF"
                ];
                env = (o.env or { }) // {
                  NIX_CFLAGS_COMPILE = (o.env.NIX_CFLAGS_COMPILE or "") + " -march=mips64r2";
                };
              });
            }
          );
        in
        lib.optionalAttrs (prev.stdenv.hostPlatform.isMips or false) {
          llvmPackages_21 = fixedLlvm;
          llvmPackages = fixedLlvm;
        }
      )

      # Cross-endian patchelf corrupts DT_MIPS_RLD_MAP_REL (LE host, BE target),
      # SIGBUSing PID 1 at boot. Unguarded: the fixupPhase patchelf is build-host.
      (_: prev: {
        patchelf = prev.patchelf.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./patches/patchelf-mips64-rld-map-rel.patch ];
        });
      })
    ];
  };
}
