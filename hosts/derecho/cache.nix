{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled stringToPort;

  port = stringToPort "nix-serve";
in
{
  secrets.nixServeKey = {
    file = self + /hosts/scarp/cache/key.age;
    owner = "root";
  };

  services.nix-serve = enabled {
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.secrets.nixServeKey.path;
    bindAddress = "0.0.0.0";
    inherit port;
  };
}
