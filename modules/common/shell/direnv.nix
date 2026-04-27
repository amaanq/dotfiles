{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.direnv
  ]
  ++ lib.optional config.isDesktop pkgs.nix-direnv;

  environment.etc = lib.mkIf config.isDesktop {
    "direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
  };
}
