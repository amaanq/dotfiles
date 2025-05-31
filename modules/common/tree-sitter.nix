{ lib, pkgs, ... }:
let
  inherit (lib) attrValues;
in
{
  environment.shellAliases = {
    ts = "tree-sitter";
    tsa = "tree-sitter-alpha";
    tss = "tree-sitter-stable";
  };

  environment.systemPackages = attrValues {
    inherit (pkgs) tree-sitter;
  };
}
