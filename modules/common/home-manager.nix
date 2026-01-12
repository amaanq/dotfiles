{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      {
        xdg = enabled { };
        manual.html.enable = false;
        manual.manpages.enable = false;
        manual.json.enable = false;
      }
    ];
  };
}
