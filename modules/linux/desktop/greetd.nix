{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;

  tuigreetConfig = (pkgs.formats.toml { }).generate "tuigreet-config.toml" {
    outputs = lib.mapAttrsToList (connector: _: {
      inherit connector;
      primary = connector == lib.head (lib.attrNames config.displayOutputs);
    }) config.displayOutputs;
  };
in
{
  services.speechd.enable = false;

  # Display manager
  services.greetd =
    let
      tuigreet = "${inputs.tuigreet.packages.${pkgs.system}.default}/bin/tuigreet";
      niri-session = "${pkgs.niri}/share/wayland-sessions";
    in
    enabled {
      settings = {
        default_session = {
          command = "${tuigreet} --config ${tuigreetConfig} --time --remember --remember-session --sessions ${niri-session}";
          user = "greeter";
        };
      };
    };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
