{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;
in
{
  environment.systemPackages = [
    pkgs.files-to-prompt
    pkgs.go
    pkgs.qbittorrent
    pkgs.sequoia-sq
    pkgs.signal-desktop
    pkgs.wabt
    pkgs.wasmtime
  ]
  ++ optionals config.isLinux [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.thunderbird
  ];

  environment.variables = {
    GOPATH = "$XDG_DATA_HOME/go";
    GOTELEMETRY = "off";
  };
}
