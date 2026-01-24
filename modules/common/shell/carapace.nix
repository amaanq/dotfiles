{ pkgs, ... }:
let
  carapace = pkgs.carapace.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./carapace-adb-devices.patch
    ];
  });

  # node-pty native addon is incompatible with Node.js 24's V8 API changes
  inshellisense = pkgs.inshellisense.override {
    buildNpmPackage = pkgs.buildNpmPackage.override { nodejs = pkgs.nodejs_22; };
  };
in
{
  environment.systemPackages = [
    carapace
    pkgs.fish
    pkgs.zsh
    inshellisense
  ];
}
