{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;
in
{
  # Only for sudoedit, see https://github.com/LordGrimmauld/run0-sudo-shim/issues/4
  security.sudo = enabled;

  environment.systemPackages = [
    pkgs.run0-sudo-shim
  ];

  # Alias sudo to run0-sudo-shim so it takes precedence over SUID wrapper.
  environment.shellAliases.sudo = "${pkgs.run0-sudo-shim}/bin/sudo";

  # Polkit rule for passwordless run0 on desktops.
  security.polkit.extraConfig = mkIf config.isDesktop ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
