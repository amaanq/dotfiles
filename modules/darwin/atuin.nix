{
  config,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  user = "amaanq";
  home = config.users.users.${user}.home;

  settings = {
    enter_accept = true;
    inline_height = 20;
    search_mode = "prefix";
    show_preview = false;
    sync.records = true;
    key_path = config.age.secrets.atuin-key.path;
    daemon = {
      enabled = true;
      socket_path = "${home}/.local/share/atuin/daemon.sock";
    };
  };
in
{
  environment.etc."atuin/config.toml".source = tomlFormat.generate "atuin-config" settings;

  launchd.user.agents.atuin-daemon.serviceConfig = {
    ProgramArguments = [
      "${lib.getExe pkgs.atuin}"
      "daemon"
    ];
    EnvironmentVariables = {
      ATUIN_LOG = "error";
    };
    KeepAlive = {
      Crashed = true;
      SuccessfulExit = false;
    };
    ProcessType = "Background";
  };
}
