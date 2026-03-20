{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  # TODO: remove once nixpkgs-unstable catches up to 2.7.7
  deno =
    (pkgs.deno.override {
      librusty_v8 = pkgs.fetchurl {
        name = "librusty_v8-146.8.0";
        url = "https://github.com/denoland/rusty_v8/releases/download/v146.8.0/librusty_v8_release_${pkgs.stdenv.hostPlatform.rust.rustcTarget}.a.gz";
        hash =
          {
            x86_64-linux = "sha256-deV+2rJD9EstgAtaFRk+z1Wk/l+j5yF9lxlLGHoCbII=";
            aarch64-linux = "sha256-zkzEqNmYuJhxXC+nYvbdKaZCGhPLONxvQ5X8u9S7/M4=";
            x86_64-darwin = "sha256-8HbKFjFm5F/+hb5lViPWok0b0NIkYXoR6RXQgHAroVo=";
            aarch64-darwin = "sha256-1AXPak0YGf53zRyPUtfPgvAn0Z03oIB9zEFbc+laAFY=";
          }
          .${pkgs.stdenv.hostPlatform.system};
        meta.sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };
    }).overrideAttrs
      (
        old:
        let
          version = "2.7.7";
          src = pkgs.fetchFromGitHub {
            owner = "denoland";
            repo = "deno";
            tag = "v${version}";
            fetchSubmodules = true;
            hash = "sha256-+RjLvdIHCSMsm/j430c3D/MuG8FdxomblkXLTsPf22I=";
          };
        in
        {
          inherit version src;
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            name = "deno-${version}-vendor.tar.gz";
            inherit src;
            hash = "sha256-ny5tV7/yG06M8DJwOZJNeZ1exemY6wyKNgXLqUixzWU=";
          };
          patches = [ ];
          buildNoDefaultFeatures = true;
          buildFeatures = [ "__vendored_zlib_ng" ];
          cargoTestFlags = [ "--test=integration_test" ];
        }
      );

  settings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    env = {
      CLAUDE_BASH_NO_LOGIN = "1";
      CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
      CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
      CLAUDE_CODE_EAGER_FLUSH = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      CLAUDE_CODE_FORCE_GLOBAL_CACHE = "1";
      CLAUDE_CODE_HIDE_ACCOUNT_INFO = "1";
      CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY = "20";
      CLAUDE_CODE_PLAN_V2_AGENT_COUNT = "5";
      CLAUDE_CODE_PLAN_V2_EXPLORE_AGENT_COUNT = "5";
      DISABLE_AUTO_COMPACT = "1";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_COST_WARNINGS = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_INSTALLATION_CHECKS = "1";
      DISABLE_TELEMETRY = "1";
      ENABLE_MCP_LARGE_OUTPUT_FILES = "1";
      ENABLE_TOOL_SEARCH = "auto:5";
      MAX_THINKING_TOKENS = "31999";
      MCP_CONNECTION_NONBLOCKING = "1";
      UV_THREADPOOL_SIZE = "16";
    };

    attribution = {
      commit = "";
      pr = "";
    };

    permissions = {
      allow = [
        "Read"
        "mcp__chrome-devtools__*"
        "mcp__ida-pro-mcp__*"
      ];
      defaultMode = "bypassPermissions";
    };

    hooks = {
      WorktreeCreate = [
        {
          hooks = [
            {
              type = "command";
              command = ''jj workspace add "$(cat /dev/stdin | jq -r '.name')"'';
            }
          ];
        }
      ];
      WorktreeRemove = [
        {
          hooks = [
            {
              type = "command";
              command = ''jj workspace forget "$(cat /dev/stdin | jq -r '.worktree_path')"'';
            }
          ];
        }
      ];
    };

    statusLine = {
      type = "command";
      command = "/etc/claude/statusline-command.nu";
    };

    enabledPlugins = {
      "clangd-lsp@claude-plugins-official" = true;
      "kotlin-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "context7@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "ralph-loop@claude-plugins-official" = true;
      "linear@claude-plugins-official" = true;
    };

    skipWebFetchPreflight = true;

    spinnerVerbs = {
      mode = "replace";
      verbs = [
        "Redeeming"
        "Clodding"
        "Tokenmaxxing"
        "Slopping"
        "Clanking"
        "Churning"
        "Forgetting"
        "Splurging"
        "Ignoring GPL"
        "Increasing ram prices"
      ];
    };

    alwaysThinkingEnabled = true;
    remoteControlAtStartup = true;
    skipDangerousModePermissionPrompt = true;
  };

  settingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON settings);

  runtimeDeps = lib.makeBinPath (
    [
      pkgs.procps
      pkgs.ripgrep
    ]
    ++ optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.bubblewrap
      pkgs.socat
    ]
  );

  patchScript = pkgs.writeScript "patch-claude-src" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./patch-claude-src.py}
  '';
in
{
  environment.systemPackages = [
    (pkgs.writeScriptBin "claude" ''
      #!${pkgs.nushell}/bin/nu --no-config-file

      $env._SETTINGS_JSON = "${settingsJson}"
      $env._DENO = "${deno}/bin/deno"
      $env._PATCH_SCRIPT = "${patchScript}"
      $env._RUNTIME_DEPS = "${runtimeDeps}"
      $env._ENV_JSON = ${lib.strings.toJSON settings.env}

      ${builtins.readFile ./launcher.nu}
    '')
  ];

  environment.etc."claude/statusline-command.nu".source = ./statusline-command.nu;

  environment.variables.CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
}
