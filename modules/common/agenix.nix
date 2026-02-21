{
  agenix,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    head
    mkAliasOptionModule
    mkIf
    ;
in
{
  imports = [ (mkAliasOptionModule [ "secrets" ] [ "age" "secrets" ]) ];

  age.identityPaths = [
    (
      if config.isServer then
        "/root/.ssh/id"
      else if config.isLinux then
        "/home/${head <| attrNames <| config.users.users}/.ssh/id"
      else
        "/Users/${head <| attrNames <| config.users.users}/.ssh/id"
    )
  ];

  environment = mkIf config.isDesktop {
    shellAliases.agenix = "agenix --identity ~/.ssh/id";
    systemPackages = [
      agenix.packages.${pkgs.system}.default
    ];
  };
}
