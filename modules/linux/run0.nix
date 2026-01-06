{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;

  run0-no-bg = pkgs.writeShellScriptBin "run0" ''
    exec ${pkgs.systemd}/bin/run0 --background= "$@"
  '';

  run0-sudo-shim' = pkgs.run0-sudo-shim.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --prefix PATH : "${run0-no-bg}/bin"
      done
    '';
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  });
in
{
  # Only for sudoedit, see https://github.com/LordGrimmauld/run0-sudo-shim/issues/4
  security.sudo = enabled;

  environment.systemPackages = [
    run0-sudo-shim'
  ];

  # Alias sudo to run0-sudo-shim so it takes precedence over SUID wrapper.
  environment.shellAliases.sudo = "${run0-sudo-shim'}/bin/sudo";

  # Polkit rule for passwordless run0 on desktops.
  security.polkit.extraConfig = mkIf config.isDesktop ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
