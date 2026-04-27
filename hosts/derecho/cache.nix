{
  self,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    filterAttrs
    mapAttrsToList
    stringToPort
    ;

  port = stringToPort "nix-serve";

  # Pin every other host's system closure as a gcroot so cross-compiled
  # artifacts built here survive nix-collect-garbage.
  otherHosts = filterAttrs (
    n: _: n != config.networking.hostName && n != "lahar"
  ) inputs.self.nixosConfigurations;

  flakeHostsPin = pkgs.linkFarm "flake-hosts-gcroots" (
    mapAttrsToList (name: c: {
      inherit name;
      path = c.config.system.build.toplevel;
    }) otherHosts
  );
in
{
  imports = [ inputs.harmonia.nixosModules.harmonia ];

  secrets.nixServeKey = {
    rekeyFile = self + /hosts/scarp/cache/key.age;
    owner = "root";
  };

  systemd.tmpfiles.rules = [
    "L+ /nix/var/nix/gcroots/flake-hosts - - - - ${flakeHostsPin}"
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
