{ config, lib, ... }:
let
  inherit (lib) mkValue;
in
{
  options.unfree.allowedNames = mkValue [ ];

  config.nixpkgs.config.allowUnfreePredicate =
    package: lib.elem (lib.getName package) config.unfree.allowedNames;
}
