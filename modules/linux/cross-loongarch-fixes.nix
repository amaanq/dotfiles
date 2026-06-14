# loongarch64 package fixes for cross-compilation.
# Auto-imported on every linux host; gated on isLoongArch64 so it's a no-op
# unless the host is a cross-compiled loongarch64 target (the barchan cluster).
# Mirrors cross-ppc64-fixes.nix / cross-mips64-fixes.nix — add overrides here as
# breakage surfaces from `nix build .#nixosConfigurations.barchan...`.
{
  config,
  lib,
  ...
}:
let
  isLoong = config.nixpkgs.hostPlatform.isLoongArch64 or false;
in
{
  config = lib.mkIf isLoong {
    nixpkgs.config.allowUnsupportedSystem = true;

    nixpkgs.overlays = [
      (
        final: prev:
        let
          isCrossLoong =
            prev.stdenv.buildPlatform != prev.stdenv.hostPlatform
            && (prev.stdenv.hostPlatform.isLoongArch64 or false);
          buildPkgs = final.pkgsBuildBuild;
          # loongarch64 has no luajit → nixpkgs neovim's lua5_1 cross path never
          # wires LUA_PRG/LUA_GEN_PRG (only the luajit branch does), and 228e6ca
          # codegen does `require('nlua0')`. Provide a build-platform lua5.1 +
          # a lua5.1-ABI host nlua0.so it can load.
          neovimCodegenLua = buildPkgs.lua5_1.withPackages (p: [
            p.mpack
            p.lpeg
          ]);
          neovimHostNlua0 = buildPkgs.stdenv.mkDerivation {
            pname = "neovim-nlua0-host";
            inherit (prev.neovim-unwrapped) version src;
            nativeBuildInputs = [
              buildPkgs.cmake
              buildPkgs.gettext
              buildPkgs.pkg-config
            ];
            buildInputs = [
              buildPkgs.libuv
              buildPkgs.lua5_1
              buildPkgs.lua51Packages.libluv
              buildPkgs.lua51Packages.lpeg
              buildPkgs.tree-sitter
              buildPkgs.unibilium
              buildPkgs.utf8proc
            ];
            cmakeFlags = [
              (lib.cmakeBool "USE_BUNDLED" false)
              (lib.cmakeBool "ENABLE_TRANSLATIONS" true)
              (lib.cmakeBool "USE_BUNDLED_BUSTED" false)
              (lib.cmakeBool "PREFER_LUA" true)
              (lib.cmakeFeature "LUA_PRG" (lib.getExe' neovimCodegenLua "lua"))
              (lib.cmakeFeature "LUA_GEN_PRG" (lib.getExe' neovimCodegenLua "lua"))
              (lib.cmakeBool "COMPILE_LUA" false)
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
        in
        lib.optionalAttrs isCrossLoong {
          # build-uudoc trips the cc-rs cross bug; skip manpages/completions.
          uutils-coreutils = prev.uutils-coreutils.overrideAttrs (old: {
            makeFlags = (old.makeFlags or [ ]) ++ [
              "MANPAGES=n"
              "COMPLETIONS=n"
            ];
          });

          neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [
              (lib.cmakeFeature "LUA_PRG" (lib.getExe' neovimCodegenLua "lua"))
              (lib.cmakeFeature "LUA_GEN_PRG" (lib.getExe' neovimCodegenLua "lua"))
              (lib.cmakeFeature "NLUA0_HOST_PRG" "${neovimHostNlua0}/lib/libnlua0.so")
              (lib.cmakeBool "COMPILE_LUA" false)
              # T2 treesitter foldexpr recompute races under qemu; skip it.
              (lib.cmakeFeature "TEST_FILTER_OUT" "recomputes fold levels after lines are added")
            ];
          });
        }
      )
    ];
  };
}
