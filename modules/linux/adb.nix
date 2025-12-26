{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    const
    filterAttrs
    getAttr
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  programs.adb.enable = config.isLinux;

  users.extraGroups.adbusers.members =
    config.users.users |> filterAttrs (const <| getAttr "isNormalUser") |> attrNames;
}
