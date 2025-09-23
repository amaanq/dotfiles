{ pkgs, ... }:
{
  environment.shellAliases = {
    sc = "systemctl";
    scd = "systemctl stop";
    scr = "systemctl restart";
    scs = "systemctl status";
    scu = "systemctl start";
    suc = "systemctl --user";
    sucd = "systemctl --user stop";
    sucr = "systemctl --user restart";
    sucs = "systemctl --user status";
    sucu = "systemctl --user start";

    jc = "journalctl";
    jcf = "journalctl --follow --unit";
    jcr = "journalctl --reverse --unit";
    juc = "journalctl --user";
    jucf = "journalctl --user --follow --unit";
    jucr = "journalctl --user --reverse --unit";
  };

  systemd.package = pkgs.systemd.overrideAttrs (oldAttrs: {
    version = "257.9";
    src = pkgs.fetchFromGitHub {
      owner = "systemd";
      repo = "systemd";
      rev = "v257.9";
      sha256 = "sha256-3Ig5TXhK99iOu41k4c5CgC4R3HhBftSAb9UbXvFY6lo=";
    };
  });
}
