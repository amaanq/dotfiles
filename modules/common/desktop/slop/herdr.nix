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
    ui.sidebar.agents = {
      row_gap = 0;
      rows = [
        [
          "state_icon"
          "workspace"
          "tab"
        ]
      ];
    };
  };
in
{
  # Local fork with nested-agent support.
  nixpkgs.overlays = [
    (final: _: {
      herdr = (final.callPackage "${herdr-src}/nix/package.nix" { }).overrideAttrs {
        src = herdr-src;
        cargoDeps = final.rustPlatform.fetchCargoVendor {
          src = herdr-src;
          hash = "sha256-XHzZy2tKLbMQy4POmXowUcGf77ZPunG/oQ3P2wOoVls=";
        };
      };
    })
  ];

  # After reboot: `herdr`
  environment.systemPackages = [ pkgs.herdr ];

  environment.etc."herdr/config.toml".source = configFile;
  environment.variables.HERDR_CONFIG_PATH = "/etc/herdr/config.toml";
}
