{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.avahi = enabled {
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = enabled {
    drivers = [
      pkgs.cups-filters
      pkgs.cups-browsed
    ];
  };
}
