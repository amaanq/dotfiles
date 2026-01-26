{
  config,
  lib,
  helium,
  ...
}:
let
  inherit (lib)
    mkIf
    optionals
    ;
in
mkIf config.isDesktop {
  wrappers.helium = {
    basePackage = helium.packages.${config.hostSystem}.helium;
    systemWide = true;
    executables.helium.args.suffix = optionals config.isLinux [ "--use-angle=vulkan" ] ++ [
      "--enable-quic"
      "--quic-version=h3-29"
    ];
  };

  environment.variables.BROWSER = "helium";
}
