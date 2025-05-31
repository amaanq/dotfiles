{ lib, pkgs, ... }:
let
  inherit (lib) attrValues;
in
{
  environment.systemPackages = attrValues {
    inherit (pkgs)
      python314
      uv
      ruff
      ;
  };

  environment.shellAliases = {
    py = "python";
  };

  environment.variables = {
    PIP_REQUIRE_VIRTUALENV = "1";
    PYTHONUNBUFFERED = "1";
  };
}
