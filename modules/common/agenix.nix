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

  agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    inherit (pkgs) shellcheck;
  };
  userName = head <| attrNames <| config.users.users;
  identityPathKey = if config.isServer then "server" else config.os;
  identityPaths = {
    server = [ "/etc/ssh/ssh_host_ed25519_key" ];
    linux = [ "/home/${userName}/.ssh/id" ];
    darwin = [ "/Users/${userName}/.ssh/id" ];
  };
in
{
  imports = [ (mkAliasOptionModule [ "secrets" ] [ "age" "secrets" ]) ];

  age.identityPaths = identityPaths.${identityPathKey};

  environment = mkIf config.isDesktop {
    systemPackages = [ agenixPackage ];
  };
}
