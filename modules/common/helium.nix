{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    optionals
    ;

  heliumPackage = import ../../packages/helium-package.nix { inherit lib pkgs; };
in
mkIf config.isDesktop {
  wrappers.helium = {
    basePackage = heliumPackage;
    systemWide = true;
    executables.helium.args.suffix = optionals config.isLinux [
      "--ignore-gpu-blocklist"
    ] ++ [
      "--enable-quic"
      "--quic-version=h3-29"
    ];
  };

  environment.variables.BROWSER = "helium";
}
