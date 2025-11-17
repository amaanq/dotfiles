{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf enabled;
in
merge
<| mkIf config.isDesktop {
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
