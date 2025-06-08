{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    const
    enabled
    filterAttrs
    getAttr
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  networking.networkmanager = enabled;

  users.extraGroups.networkmanager.members =
    config.users.users |> filterAttrs (const <| getAttr "isNormalUser") |> attrNames;

  environment.shellAliases.wifi = "nmcli dev wifi show-password";
}
