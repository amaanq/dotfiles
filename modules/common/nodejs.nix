{ pkgs, ... }:
let
  # TODO: remove once nixpkgs-unstable catches up to 2.6.10
  deno = (pkgs.deno.override {
    librusty_v8 = pkgs.fetchurl {
      name = "librusty_v8-145.0.0";
      url = "https://github.com/denoland/rusty_v8/releases/download/v145.0.0/librusty_v8_release_${pkgs.stdenv.hostPlatform.rust.rustcTarget}.a.gz";
      hash = {
        x86_64-linux = "sha256-chV1PAx40UH3Ute5k3lLrgfhih39Rm3KqE+mTna6ysE=";
        aarch64-linux = "sha256-4IivYskhUSsMLZY97+g23UtUYh4p5jk7CzhMbMyqXyY=";
        x86_64-darwin = "sha256-1jUuC+z7saQfPYILNyRJanD4+zOOhXU2ac/LFoytwho=";
        aarch64-darwin = "sha256-yHa1eydVCrfYGgrZANbzgmmf25p7ui1VMas2A7BhG6k=";
      }.${pkgs.stdenv.hostPlatform.system};
      meta.sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
    };
  }).overrideAttrs (old: let
    version = "2.6.10";
    src = pkgs.fetchFromGitHub {
      owner = "denoland";
      repo = "deno";
      tag = "v${version}";
      fetchSubmodules = true;
      hash = "sha256-youaF9YERkGUwN0sg6IzV8OAyahSDbFt0psn/p4iOVY=";
    };
  in {
    inherit version src;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      name = "deno-${version}-vendor.tar.gz";
      inherit src;
      hash = "sha256-goaqxj8Y5Gqo4et4AkyZ3Uv74Q3M3V0VExUA/AMYNMI=";
    };
    patches = [ ];
    buildNoDefaultFeatures = true;
    buildFeatures = [ "__vendored_zlib_ng" ];
    cargoTestFlags = [ "--test=integration_test" ];
  });
in
{
  _module.args.deno = deno;

  environment.systemPackages = [
    pkgs.nodejs
    deno
  ];

  environment.variables = {
    NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
    NPM_CONFIG_INIT_MODULE = "$XDG_CONFIG_HOME/npm/config/npm-init.js";
    NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
    NPM_CONFIG_UPDATE_NOTIFIER = "false";
    NEXT_TELEMETRY_DISABLED = "1";
  };
}
