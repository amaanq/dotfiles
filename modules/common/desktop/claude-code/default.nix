{

  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  chrome-devtools-mcp =
    let
      version = "0.17.3";
    in
    pkgs.writeShellScriptBin "chrome-devtools-mcp" ''
      set -euo pipefail
      export PATH="${pkgs.deno}/bin:$PATH"

      CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/chrome-devtools-mcp"
      BIN="$CACHE/chrome-devtools-mcp-${version}"

      if [ ! -x "$BIN" ]; then
        mkdir -p "$CACHE"
        DENO_DIR="$CACHE/.deno"
        export DENO_DIR
        deno cache "npm:chrome-devtools-mcp@${version}"
        # Kill Clearcut telemetry watchdog — stub out WatchdogClient
        cat > "$DENO_DIR/npm/registry.npmjs.org/chrome-devtools-mcp/${version}/build/src/telemetry/WatchdogClient.js" <<'STUB'
      export class WatchdogClient { constructor() {} send() {} }
      STUB
        deno compile --allow-all --output "$BIN" "npm:chrome-devtools-mcp@${version}" 2>&1
        rm -rf "$DENO_DIR"
      fi

      exec "$BIN" --no-usage-statistics "$@"
    '';

  rtk = pkgs.rustPlatform.buildRustPackage {
    pname = "rtk";
    version = "0.34.1";

    src = pkgs.fetchFromGitHub {
      owner = "rtk-ai";
      repo = "rtk";
      tag = "v0.34.1";
      hash = "sha256-f9bhFkJ1d4S791iouIqyz0wOyghScvdpHpQKLC+UxJM=";
    };

    cargoHash = "sha256-DCVYkznC91OP50FxaigW0q/mVLclYLTy7nAShnK11yE=";

    doCheck = false;

    meta = {
      description = "CLI proxy that reduces LLM token consumption by filtering command output";
      homepage = "https://github.com/rtk-ai/rtk";
      license = lib.licenses.mit;
      mainProgram = "rtk";
    };
  };

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
      RTK_TELEMETRY_DISABLED = "1";
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
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "/home/amaanq/.claude/hooks/rtk-rewrite.sh";
            }
          ];
        }
      ];
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

    cleanupPeriodDays = 90;
    alwaysThinkingEnabled = true;
    remoteControlAtStartup = true;
    showClearContextOnPlanAccept = true;
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

  liftScript = pkgs.writeScript "lift-claude-bun" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./lift-claude-bun.py}
  '';

  # Packages that bun's --compile leaves as runtime-external. Bun's runtime
  # supplies them natively; deno has no such provision, so we must declare
  # them as real deps and bundle a node_modules/ tree into the executable.
  externalPackageJson = pkgs.writeText "claude-code-external-package.json" (builtins.toJSON {
    name = "claude-code-lifted";
    type = "commonjs";
    dependencies = {
      ws = "^8";
      undici = "^6";
      node-fetch = "^3";
      ajv = "^8";
      ajv-formats = "^3";
      yaml = "^2";
    };
  });
in
{
  environment.systemPackages = [
    chrome-devtools-mcp
    rtk
    (pkgs.writeScriptBin "claude" ''
      #!${pkgs.nushell}/bin/nu --no-config-file

      $env._SETTINGS_JSON = "${settingsJson}"
      $env._DENO = "${pkgs.deno}/bin/deno"
      $env._PATCH_SCRIPT = "${patchScript}"
      $env._LIFT_SCRIPT = "${liftScript}"
      $env._EXTERNAL_PACKAGE_JSON = "${externalPackageJson}"
      $env._TAR = "${pkgs.gnutar}/bin/tar"
      $env._RUNTIME_DEPS = "${runtimeDeps}"
      $env._ENV_JSON = ${lib.strings.toJSON settings.env}

      ${builtins.readFile ./launcher.nu}
    '')
  ];

  environment.etc."claude/statusline-command.nu".source = ./statusline-command.nu;

  environment.variables.CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
}
