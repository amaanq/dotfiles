{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nodejs
    pkgs.deno
  ];
}
