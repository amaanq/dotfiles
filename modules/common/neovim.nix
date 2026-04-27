{
  config,
  nvim-config,
  pkgs,
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
    (pkgs.extend nvim-config.overlays.${variant}).${variant}
  ];
}
