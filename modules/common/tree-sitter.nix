{ pkgs, ... }:
{
  environment.shellAliases = {
    ts = "tree-sitter";
    tsa = "tree-sitter-alpha";
    tss = "tree-sitter-stable";
  };

  environment.systemPackages = [
    (pkgs.tree-sitter.overrideAttrs (old: rec {
      version = "0.25.8";
      src = pkgs.fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter";
        tag = "v${version}";
        hash = "sha256-q465DMTiFHoOZy6cMvrSywwO1qJVXPmQ0OVIPmwib6c=";
        fetchSubmodules = true;
      };

      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-5xtsNE94J5Hg8rGkyzx8P6c8vl1x17zgpSulcGNVKmI=";
      };
    }))
    pkgs.python313Packages.pytest
  ];
}
