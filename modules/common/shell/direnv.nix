{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.direnv
    pkgs.nix-direnv
  ];

  environment.etc."direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
}
