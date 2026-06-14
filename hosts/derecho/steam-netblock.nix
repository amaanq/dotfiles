{ pkgs, ... }:
let
  script = pkgs.runCommand "netblock-nu" { } ''
    install -Dm444 ${./steam-netblock.nu} $out/netblock
  '';
in
{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "netblock";
      runtimeInputs = [
        pkgs.nushell
        pkgs.nftables
        pkgs.procps
        pkgs.coreutils
        pkgs.iproute2
      ];
      text = ''
        if [ "$(id -u)" -ne 0 ]; then exec sudo "$0" "$@"; fi
        exec nu ${script}/netblock "$@"
      '';
    })
  ];

  programs.niri.settings.binds."Mod+Alt+P".action.spawn = [
    "sh"
    "-c"
    ''${pkgs.libnotify}/bin/notify-send -a netblock netblock "$(netblock toggle)"''
  ];
}
