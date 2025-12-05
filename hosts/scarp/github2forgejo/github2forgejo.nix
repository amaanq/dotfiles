{ config, lib, ... }:
let
  inherit (lib) enabled;
in
{
  secrets.github2forgejoEnvironment.file = ./environment.age;

  services.github2forgejo = enabled {
    environmentFile = config.secrets.github2forgejoEnvironment.path;
  };
}
