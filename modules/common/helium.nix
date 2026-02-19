{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    optionals
    ;

  heliumPackage = inputs.helium.packages.${pkgs.system}.helium;
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
