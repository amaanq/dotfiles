{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf;
  heliumPackage = import ../../packages/helium-package.nix { inherit lib pkgs; };
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    heliumPackage
  ];

  # Set as default browser
  xdg.mime.defaultApplications = {
    "text/html" = "helium.desktop";
    "x-scheme-handler/http" = "helium.desktop";
    "x-scheme-handler/https" = "helium.desktop";
  };
}
