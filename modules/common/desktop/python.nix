{ pkgs, ... }:
let
  package = pkgs.python314;
in
{
  environment.variables = {
    PIP_REQUIRE_VIRTUALENV = "1";
    PYTHON_HISTORY = "$XDG_STATE_HOME/python_history";
    PYTHONUNBUFFERED = "1";
    UV_PYTHON_PREFERENCE = "system";
    UV_PYTHON = "${package}";
  };

  environment.etc."ruff/ruff.toml".text = ''
    indent-width = 3

    [lint]
    ignore = ["E1"]
  '';

  environment.shellAliases = {
    py = "python";
  };

  environment.systemPackages = [
    package
    pkgs.uv
  ];
}
