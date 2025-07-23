{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nodejs
    pkgs.bun
  ];
}
