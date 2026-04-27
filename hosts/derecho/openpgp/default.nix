{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.gnupg
    pkgs.sequoia-sq
    pkgs.pinentry-curses
  ];
}
