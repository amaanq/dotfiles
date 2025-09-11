{ pkgs, ... }:
{
  environment.shellAliases = {
    ts = "tree-sitter";
    tsa = "tree-sitter-alpha";
    tss = "tree-sitter-stable";
  };

  environment.systemPackages = [
    (pkgs.tree-sitter.overrideAttrs (old: rec {
      version = "0.25.9";
      src = pkgs.fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter";
        tag = "v${version}";
        hash = "sha256-i7sptOJuLPSl0v8qYF54zfvVKOUtekcFedqapxehzWI=";
        fetchSubmodules = true;
      };

      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-0Do1UxIbfIfJ61dTiJt0ZGDrhOtGV0l9bafyoqcbqgU=";
      };
    }))
    pkgs.python313Packages.pytest
  ];
}
