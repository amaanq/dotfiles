{
  inputs,
  pkgs,
  ...
}:
let
  heliumPackage = inputs.helium.packages.${pkgs.system}.helium;
in
{
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
