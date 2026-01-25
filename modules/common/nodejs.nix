{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nodejs
    pkgs.deno
  ];

  environment.variables = {
    NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
    NPM_CONFIG_INIT_MODULE = "$XDG_CONFIG_HOME/npm/config/npm-init.js";
    NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
    NPM_CONFIG_UPDATE_NOTIFIER = "false";
  };
}
