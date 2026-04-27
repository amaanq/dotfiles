{ ... }:
{
  # Quirks for x86_64 → aarch64 cross builds. The overlay is a no-op on
  # native builds and on non-aarch64 targets, so it's safe to load on every
  # linux host.
  nixpkgs.overlays = [
    (
      final: prev:
      let
        isCrossAarch64 =
          prev.stdenv.buildPlatform != prev.stdenv.hostPlatform && prev.stdenv.hostPlatform.isAarch64;
      in
      if !isCrossAarch64 then
        { }
      else
        let
          buildPlatformCcEnv =
            let
              buildConfigUnderscored = prev.lib.replaceStrings [ "-" ] [ "_" ] prev.stdenv.buildPlatform.config;
            in
            {
              "CC_${buildConfigUnderscored}" = "${final.pkgsBuildBuild.stdenv.cc}/bin/cc";
              "CXX_${buildConfigUnderscored}" = "${final.pkgsBuildBuild.stdenv.cc}/bin/c++";
            };
          buildPlatformBindgenEnv =
            let
              buildConfigUnderscored = prev.lib.replaceStrings [ "-" ] [ "_" ] prev.stdenv.buildPlatform.config;
            in
            {
              "BINDGEN_EXTRA_CLANG_ARGS_${buildConfigUnderscored}" =
                "-isystem ${final.pkgsBuildBuild.stdenv.cc.libc.dev}/include";
            };

          useBuildPlatformCcForRustBuildScripts =
            pkg:
            pkg.overrideAttrs (old: {
              env = (old.env or { }) // buildPlatformCcEnv;
            });

          neovimHostNlua0 =
            let
              buildPkgs = final.pkgsBuildBuild;
            in
            buildPkgs.stdenv.mkDerivation {
              pname = "neovim-nlua0-host";
              inherit (prev.neovim-unwrapped) version src;

              nativeBuildInputs = [
                buildPkgs.cmake
                buildPkgs.gettext
                buildPkgs.pkg-config
              ];
              buildInputs = [
                buildPkgs.libuv
                buildPkgs.luajit
                buildPkgs.luajitPackages.libluv
                buildPkgs.luajitPackages.lpeg
                buildPkgs.tree-sitter
                buildPkgs.unibilium
                buildPkgs.utf8proc
              ];
              cmakeFlags = [
                (final.lib.cmakeBool "USE_BUNDLED" false)
                (final.lib.cmakeBool "ENABLE_TRANSLATIONS" true)
                (final.lib.cmakeBool "USE_BUNDLED_BUSTED" false)
              ];
              buildPhase = ''
                runHook preBuild
                cmake --build . --target nlua0
                runHook postBuild
              '';
              installPhase = ''
                runHook preInstall
                install -D lib/libnlua0.so "$out/lib/libnlua0.so"
                runHook postInstall
              '';
            };

          luaPackageOverrides = lfinal: lprev: {
            busted = lprev.busted.overrideAttrs (old: {
              dontStrip = true;
              postFixup = (old.postFixup or "") + ''
                grep -RIlE \
                  -e '/nix/store/[a-z0-9]+-luajit-2\.1\.1741730670' \
                  -e '/nix/store/[a-z0-9]+-luarocks_bootstrap-3\.13\.0' \
                  -e '/nix/store/[a-z0-9]+-bash-interactive-5\.3p9' \
                  "$out" \
                | while IFS= read -r file; do
                  sed -i -E \
                    -e 's#/nix/store/[a-z0-9]+-luajit-2\.1\.1741730670#${final.luajit}#g' \
                    -e 's#/nix/store/[a-z0-9]+-luarocks_bootstrap-3\.13\.0#${lfinal.luarocks_bootstrap}#g' \
                    -e 's#/nix/store/[a-z0-9]+-bash-interactive-5\.3p9#${final.bashInteractive}#g' \
                    "$file"
                done
              '';
            });
          };
        in
        {
          # ring's build-host C snippets pick up the cross $CC; force them
          # at the build-platform compiler explicitly.
          atuin = useBuildPlatformCcForRustBuildScripts prev.atuin;
          xh = useBuildPlatformCcForRustBuildScripts prev.xh;

          # rquickjs-sys's build-host run inherits BINDGEN_EXTRA_CLANG_ARGS
          # from the aarch64 hook; patch its build.rs to swap to host paths
          # when OUT_DIR isn't on the cross target.
          tree-sitter = prev.tree-sitter.overrideAttrs (old: {
            env = (old.env or { }) // buildPlatformCcEnv // buildPlatformBindgenEnv;
            preBuild = (old.preBuild or "") + ''
              export BINDGEN_NATIVE_CLANG_ARGS="-isystem ${final.pkgsBuildBuild.stdenv.cc.libc_dev}/include -isystem ${final.pkgsBuildBuild.llvmPackages.libclang.lib}/lib/clang/${prev.lib.versions.major final.pkgsBuildBuild.llvmPackages.libclang.version}/include"
              export NATIVE_HOST_CC="${final.pkgsBuildBuild.stdenv.cc}/bin/cc"
              export NATIVE_HOST_CXX="${final.pkgsBuildBuild.stdenv.cc}/bin/c++"
              export NATIVE_HOST_AR="${final.pkgsBuildBuild.stdenv.cc.bintools}/bin/ar"
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
                    'let mut target = env::var("TARGET").unwrap(); { let host = env::var("HOST").unwrap_or_default(); let out_dir_env = env::var("OUT_DIR").unwrap_or_default(); let native_args = env::var("BINDGEN_NATIVE_CLANG_ARGS").unwrap_or_default(); let is_native_artifact = !out_dir_env.contains("/aarch64-") && !out_dir_env.contains("/powerpc64-"); if is_native_artifact { unsafe { env::set_var("BINDGEN_EXTRA_CLANG_ARGS", &native_args); if target != host { env::set_var("TARGET", &host); } if let Ok(cc) = env::var("NATIVE_HOST_CC") { env::set_var("CC", &cc); env::set_var(format!("CC_{}", host.replace("-", "_")), &cc); } if let Ok(cxx) = env::var("NATIVE_HOST_CXX") { env::set_var("CXX", &cxx); env::set_var(format!("CXX_{}", host.replace("-", "_")), &cxx); } if let Ok(ar) = env::var("NATIVE_HOST_AR") { env::set_var("AR", &ar); env::set_var(format!("AR_{}", host.replace("-", "_")), &ar); } env::remove_var("CFLAGS"); env::remove_var("CXXFLAGS"); env::remove_var(format!("CFLAGS_{}", target.replace("-", "_"))); env::remove_var(format!("CXXFLAGS_{}", target.replace("-", "_"))); } target = host.clone(); } } eprintln!("[rquickjs-patch-runtime] target={} OUT_DIR={} CC={} BINDGEN_EXTRA_CLANG_ARGS={}", target, env::var("OUT_DIR").unwrap_or_default(), env::var("CC").unwrap_or_default(), env::var("BINDGEN_EXTRA_CLANG_ARGS").unwrap_or_default());' \
                  --replace-fail \
                    'let mut cflags = vec![format!("--target={}", target)];' \
                    'let mut cflags = vec![format!("--target={}", target)]; if let Ok(extra) = env::var("BINDGEN_EXTRA_CLANG_ARGS") { for a in extra.split_whitespace() { cflags.push(a.to_string()); } } eprintln!("[rquickjs-patch-runtime] cflags={:?}", cflags);'
                patched_any=1
              done
              if [ "$patched_any" = 0 ]; then
                echo "[rquickjs-patch] WARNING: no rquickjs-sys/build.rs matched!"
              fi
            '';
          });

          # Build neovim's nlua0 helper for the build host so codegen can
          # load it; the target build keeps its own aarch64 copy.
          neovim-unwrapped =
            (prev.neovim-unwrapped.override { tree-sitter = final.tree-sitter; }).overrideAttrs
              (old: {
                cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                  (final.lib.cmakeFeature "NLUA0_HOST_PRG" "${neovimHostNlua0}/lib/libnlua0.so")
                ];
              });

          # Strip build-host paths from busted's generated luarocks metadata.
          luajit = prev.luajit.override { packageOverrides = luaPackageOverrides; };
          luajitPackages = final.luajit.pkgs;

          # build-uudoc trips the cc-rs cross bug; skip manpages/completions.
          uutils-coreutils = prev.uutils-coreutils.overrideAttrs (old: {
            makeFlags = (old.makeFlags or [ ]) ++ [
              "MANPAGES=n"
              "COMPLETIONS=n"
            ];
          });

          # carapace's preBuild `go generate` needs a host CC; point CC at
          # the build-host gcc just for that step.
          carapace = prev.carapace.overrideAttrs (_: {
            preBuild = ''
              CC=${final.pkgsBuildBuild.stdenv.cc}/bin/cc \
              CXX=${final.pkgsBuildBuild.stdenv.cc}/bin/c++ \
              GOOS= GOARCH= go generate ./...
            '';
          });

          # python jc: postInstall runs the cross-built jc binary to generate
          # shell completions, which can't execute on the build host. Skip it.
          python313 = prev.python313.override {
            packageOverrides = _: pyprev: {
              jc = pyprev.jc.overrideAttrs (_: {
                postInstall = "";
              });
            };
          };

          # bch_bindgen layout_tests underflow at const-eval on cross
          # (host libclang reports align=1 for packed bitfields, bindgen
          # bakes in 4). Disable layout tests via a real patch — postPatch
          # is silently swallowed by cargoSetupPostPatchHook.
          bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./patches/bcachefs-tools-disable-layout-tests.patch
            ];
          });
        }
    )
  ];
}
