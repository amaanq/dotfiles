{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  settings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    env = {
      CLAUDE_BASH_NO_LOGIN = "1";
      CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
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
      $env._DENO = "${pkgs.deno}/bin/deno"
      $env._PATCH_SCRIPT = "${patchScript}"
      $env._RUNTIME_DEPS = "${runtimeDeps}"
      $env._ENV_JSON = ${lib.strings.toJSON settings.env}

      ${builtins.readFile ./launcher.nu}
    '')
  ];

  environment.etc."claude/statusline-command.nu".source = ./statusline-command.nu;

  environment.variables.CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
}
