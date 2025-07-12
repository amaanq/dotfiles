{ config, lib, ... }:
let
  inherit (lib) mkValue;
in
{
  options.unfree.allowedNames = mkValue [ ];

  config.nixpkgs.config.allowUnfreePredicate =
    package: lib.elem (package.pname or package.name) config.unfree.allowedNames;
}
