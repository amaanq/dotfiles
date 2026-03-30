{
  config,
  nvim-config,
  ...
}:
let
  variant = if config.isServer then "server" else "nvim";
in
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = [
    nvim-config.packages.${config.hostSystem}.${variant}
  ];
}
