{
  config,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    enter_accept = true;
    inline_height = 20;
    search_mode = "prefix";
    show_preview = false;
    sync.records = true;
    key_path = config.age.secrets.atuin-key.path;
    daemon = {
      enabled = true;
      systemd_socket = true;
    };
  };
in
{
  environment.etc."atuin/config.toml".source = tomlFormat.generate "atuin-config" settings;

  systemd.user.services.atuin-daemon = {
    description = "Atuin daemon";
    requires = [ "atuin-daemon.socket" ];
    after = [ "atuin-daemon.socket" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.atuin} daemon";
      Environment = [
        "ATUIN_LOG=error"
        "ATUIN_CONFIG_DIR=/etc/atuin"
      ];
      Restart = "on-failure";
      RestartSteps = 3;
      RestartMaxDelaySec = 6;
    };
  };

  systemd.user.sockets.atuin-daemon = {
    description = "Atuin daemon socket";
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/atuin.sock";
      SocketMode = "0600";
      RemoveOnStop = true;
    };
  };
}
