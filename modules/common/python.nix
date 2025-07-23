{ pkgs, ... }:
let
  package = pkgs.python314;
in
{
  environment.variables = {
    PIP_REQUIRE_VIRTUALENV = "1";
    PYTHONUNBUFFERED = "1";
    UV_PYTHON_PREFERENCE = "system";
    UV_PYTHON = "${package}";
  };

  environment.shellAliases = {
    py = "python";
  };

  environment.systemPackages = [
    package
    pkgs.uv
  ];
}
