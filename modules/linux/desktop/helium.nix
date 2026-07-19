{
  lib,
  pkgs,
  helium,
  ...
}:
let
  inherit (lib) const flip genAttrs;

  heliumPackage = helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
in
{
  environment.systemPackages = [
    heliumPackage
  ];

  # Set as default browser
  xdg.mime.defaultApplications =
    [
      "text/html"
      "text/xml"
      "application/pdf"
      "application/rdf+xml"
      "application/xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/x-extension-htm"
      "application/x-extension-html"
      "application/x-extension-shtml"
      "application/x-extension-xht"
      "application/x-extension-xhtml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "x-scheme-handler/about"
      "x-scheme-handler/chrome"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/unknown"
    ]
    |> flip genAttrs (const "helium.desktop");
}
