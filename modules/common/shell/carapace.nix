{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Upstream ships a Node SEA binary per platform so we don't have to drag
  # nodejs_22 into the closure just for inshellisense.
  # https://github.com/microsoft/inshellisense/issues/369
  inshellisense = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "inshellisense";
    version = "0.0.1";

    src =
      let
        arch =
          {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          }
          .${pkgs.stdenv.hostPlatform.system};
        hashes = {
          "linux-x64" = "sha256-jXw0/b6gEMgi5jxxxJt4qkrcEavTH3iRXbfihr5PEts=";
          "linux-arm64" = "sha256-d+7ozE9gF/CX0V7bMA0uGG/ARlV87n7pU0hQzpN8MEg=";
          "darwin-x64" = "sha256-DO+zBij/8dIDVRRVsKCb9G9jwRtK++N/al/0B2UJbwE=";
          "darwin-arm64" = "sha256-RUdepOT/dTcFleNrXn5tlhU4yHSpVsRvnRbTwuqvFn4=";
        };
      in
      pkgs.fetchurl {
        url = "https://registry.npmjs.org/@microsoft/inshellisense-${arch}/-/inshellisense-${arch}-${finalAttrs.version}.tgz";
        hash = hashes.${arch};
      };

    dontBuild = true;

    # Node's SEA format stores the blob at a postject-computed offset that
    # patchelf invalidates by rewriting sections. Keep the binary pristine and
    # launch it through a wrapper that points at the nix dynamic linker.
    installPhase =
      if pkgs.stdenv.hostPlatform.isLinux then
        ''
          runHook preInstall
          install -Dm755 inshellisense-* $out/libexec/inshellisense
          mkdir -p $out/bin
          cat > $out/bin/inshellisense <<EOF
          #!${pkgs.runtimeShell}
          exec ${pkgs.stdenv.cc.bintools.dynamicLinker} \
            --library-path ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]} \
            $out/libexec/inshellisense "\$@"
          EOF
          chmod +x $out/bin/inshellisense
          ln -s inshellisense $out/bin/is
          runHook postInstall
        ''
      else
        ''
          runHook preInstall
          install -Dm755 inshellisense-* $out/bin/inshellisense
          ln -s inshellisense $out/bin/is
          runHook postInstall
        '';

    meta = {
      description = "IDE style command line auto complete";
      homepage = "https://github.com/microsoft/inshellisense";
      license = lib.licenses.mit;
      mainProgram = "inshellisense";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  });
in
{
  environment.systemPackages = [
    pkgs.carapace
  ]
  ++ lib.optionals config.isDesktop [
    pkgs.fish
    pkgs.zsh
    inshellisense
  ];
}
