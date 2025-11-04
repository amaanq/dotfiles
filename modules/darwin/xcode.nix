{ pkgs, ... }:
{
  unfree.allowedNames = [
    "Xcode.app"
  ];

  environment.systemPackages = [
    pkgs.darwin.xcode
  ];
}
