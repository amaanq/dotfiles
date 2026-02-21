{
  config,
  github2forgejo,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  secrets.github2forgejoEnvironment.file = ./environment.age;

  services.github2forgejo = enabled {
    package = github2forgejo.packages.${pkgs.system}.default;
    environmentFile = config.secrets.github2forgejoEnvironment.path;
  };
}
