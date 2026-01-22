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

  # Set as default browser
  xdg.mime.defaultApplications = {
    "text/html" = "helium.desktop";
    "x-scheme-handler/http" = "helium.desktop";
    "x-scheme-handler/https" = "helium.desktop";
  };
}
