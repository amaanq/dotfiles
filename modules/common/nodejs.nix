{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrValues;
in
{
  environment.systemPackages = attrValues {
    inherit (pkgs)
      nodejs
      bun
      ;
  };
}

