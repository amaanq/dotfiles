{
  config,
  lib,
  pkgs,
  run0-sudo-shim,
  ...
}:
let
  inherit (config) isDesktop type;
  inherit (lib)
    mkDefault
    ;

  polkit =
    {
      desktop = {
        exec = "YES";
        fallback = "return polkit.Result.YES;";
      };
      server = {
        exec = "AUTH_SELF_KEEP";
        fallback = "// non-sudo actions: fall through to defaults";
      };
    }
    .${type};

  run0-no-bg = pkgs.writeShellScriptBin "run0" /* sh */ ''
    exec ${pkgs.systemd}/bin/run0 --background= "$@"
  '';

  run0-sudo-shim' = run0-sudo-shim.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    env = (old.env or { }) // {
      RUN0 = "${run0-no-bg}/bin/run0";
    };
  });
in
{
  environment.systemPackages = [
    run0-sudo-shim'
  ];

  security.sudo.wheelNeedsPassword = !isDesktop;
  security.polkit.enable = mkDefault true;

  # Alias sudo/sudoedit to run0-sudo-shim so it takes precedence over SUID wrapper.
  environment.shellAliases.sudo = "${run0-sudo-shim'}/bin/sudo";
  environment.shellAliases.sudoedit = "${run0-sudo-shim'}/bin/sudo -e";

  security.polkit.extraConfig = /* javascript */ ''
    polkit.addRule(function(action, subject) {
      if (!subject.isInGroup("wheel")) return;
      if (action.id == "org.freedesktop.policykit.exec"
          || action.id.indexOf("org.freedesktop.systemd1.") == 0) {
        return polkit.Result.${polkit.exec};
      }
      ${polkit.fallback}
    });
  '';
}
