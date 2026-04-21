{
  self,
  config,
  inputs,
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
  imports = [ inputs.harmonia.nixosModules.harmonia ];

  secrets.nixServeKey = {
    rekeyFile = self + /hosts/scarp/cache/key.age;
    owner = "root";
  };

  systemd.tmpfiles.rules = [
    "L+ /nix/var/nix/gcroots/nunatak-kernel - - - - ${self.nixosConfigurations.nunatak.config.boot.kernelPackages.kernel}"
    "L+ /nix/var/nix/gcroots/ppc64-stdenv - - - - ${ppc64Pkgs.stdenv}"
  ];

  services.harmonia-dev.cache = enabled {
    signKeyPaths = [ config.secrets.nixServeKey.path ];
    settings = {
      bind = "0.0.0.0:${toString port}";
      priority = 30;
      enable_compression = true;
    };
  };
}
