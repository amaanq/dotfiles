{
  self,
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:
let
  inherit (lib) enabled stringToPort;

  port = stringToPort "nix-serve";

  ppc64Pkgs = import nixpkgs { system = "powerpc64-linux"; };
in
{
  secrets.nixServeKey = {
    file = self + /hosts/scarp/cache/key.age;
    owner = "root";
  };

  systemd.tmpfiles.rules = [
    "L+ /nix/var/nix/gcroots/nunatak-kernel - - - - ${self.nixosConfigurations.nunatak.config.boot.kernelPackages.kernel}"
    "L+ /nix/var/nix/gcroots/ppc64-stdenv - - - - ${ppc64Pkgs.stdenv}"
  ];

  services.nix-serve = enabled {
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.secrets.nixServeKey.path;
    bindAddress = "0.0.0.0";
    inherit port;
  };
}
