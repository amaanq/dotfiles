{ inputs, pkgs, ... }:
{
  imports = [ inputs.stylix.darwinModules.stylix ];

  home-manager.sharedModules = [
    {
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    }
  ];
}
