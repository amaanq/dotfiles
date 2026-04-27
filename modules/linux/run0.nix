{
  config,
  lib,
  pkgs,
  run0-sudo-shim,
  ...
}:
let
  run0-no-bg = pkgs.writeShellScriptBin "run0" ''
    exec ${pkgs.systemd}/bin/run0 --background= "$@"
  '';

  run0-sudo-shim' = run0-sudo-shim.packages.${pkgs.system}.default.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --prefix PATH : "${run0-no-bg}/bin"
      done
    '';
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  });
in
{
  environment.systemPackages = [
    run0-sudo-shim'
  ];

  security.sudo.wheelNeedsPassword = !config.isDesktop;
  security.polkit.enable = lib.mkDefault true;

  # Alias sudo/sudoedit to run0-sudo-shim so it takes precedence over SUID wrapper.
  environment.shellAliases.sudo = "${run0-sudo-shim'}/bin/sudo";
  environment.shellAliases.sudoedit = "${run0-sudo-shim'}/bin/sudo -e";

  # Desktops have passwordless sudo,but servers prompt for the user's password.
  security.polkit.extraConfig = /* javascript */ ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.${if config.isDesktop then "YES" else "AUTH_SELF_KEEP"};
      }
    });
  '';
}
