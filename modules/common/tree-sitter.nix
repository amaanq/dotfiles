{ pkgs, ... }:
{
  environment.shellAliases = {
    ts = "tree-sitter";
    tsa = "tree-sitter-alpha";
    tss = "tree-sitter-stable";
  };
  environment.systemPackages = [
    pkgs.tree-sitter
    pkgs.python313Packages.pytest
  ];
}
