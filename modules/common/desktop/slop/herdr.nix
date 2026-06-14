{ pkgs, herdr-src, ... }:
let
  configFile = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;
    keys.prefix = "backtick";
    keys.previous_tab = [
      "prefix+p"
      "prefix+["
    ];
    keys.next_tab = [
      "prefix+n"
      "prefix+]"
    ];
    keys.switch_tab = [
      "prefix+1..9"
      "ctrl+1..9"
    ];
    keys.navigate_workspace_up = [
      "up"
      "k"
    ];
    keys.navigate_workspace_down = [
      "down"
      "j"
    ];
    keys.navigate_pane_up = "";
    keys.navigate_pane_down = "";
    session.resume_agents_on_restore = true;
    session.restore_commands.nvim = [
      "nvim"
      ''+lua require("persistence").load()''
    ];
  };
in
{
  # Local fork with nested-agent support (tack pin herdr-src); the fork's
  # package.nix builds from its own Cargo.lock, so no hash bumps on update.
  nixpkgs.overlays = [
    (final: _: {
      herdr = final.callPackage "${herdr-src}/nix/package.nix" { };
    })
  ];

  # After reboot: `herdr`
  environment.systemPackages = [ pkgs.herdr ];

  environment.etc."herdr/config.toml".source = configFile;
  environment.variables.HERDR_CONFIG_PATH = "/etc/herdr/config.toml";
}
