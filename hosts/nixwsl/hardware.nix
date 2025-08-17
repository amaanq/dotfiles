{ lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkForce false;

  nixpkgs.hostPlatform = "x86_64-linux";
}
