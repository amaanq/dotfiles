{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    const
    filterAttrs
    getAttr
    ;
in
{
  users.extraGroups.adbusers.members =
    config.users.users |> filterAttrs (const <| getAttr "isNormalUser") |> attrNames;
}
