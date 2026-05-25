{
  config,
  lib,
  nvim-config,
  pkgs,
  ...
}:
let
  variant = if config.isServer then "server" else "nvim";
  nvimPackage = (pkgs.extend nvim-config.overlays.${variant}).${variant};
in
{
  options.neovimPackage = lib.mkConst nvimPackage;

  config = {
    environment.variables = {
      EDITOR = "nvim";
    };

    environment.systemPackages = [ nvimPackage ];
  };
}
