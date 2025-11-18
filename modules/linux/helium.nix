{
  config,
  lib,
  helium,
  ...
}:
let
  inherit (lib) merge mkIf;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    helium.packages.x86_64-linux.default
  ];
}
