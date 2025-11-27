{ lib, pkgs, ... }:
let
  inherit (lib) enabled;

  carapace = pkgs.carapace.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./carapace-adb-devices.patch
    ];
  });
in
{
  environment.systemPackages = [
    carapace
    pkgs.fish
    pkgs.zsh
    pkgs.inshellisense
  ];

  home-manager.sharedModules = [
    {
      programs.carapace = enabled {
        package = carapace;
      };
    }
  ];
}
