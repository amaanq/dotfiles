{
  config,
  lib,
  nvim-config,
  pkgs,
  ...
}:
let
  variant =
    {
      desktop = "nvim";
      server = "server";
    }
    .${config.type};
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
