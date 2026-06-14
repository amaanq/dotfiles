{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;

  codexVersion = "0.144.6";

  src = pkgs.fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${codexVersion}";
    hash = "sha256-S25nhnF4lEJQdiyKDV38ORbjm+BNsswLoE5ivF0SE2U=";
  };

  # Verbatim copy of rtk-ai/rtk's hooks/codex/rtk-awareness.md --
  # codex has no transparent rewrite hook, only prompt-level guidance.
  rtkMd = pkgs.writeText "codex-rtk.md" ''
    # RTK - Rust Token Killer (Codex CLI)

    **Usage**: Token-optimized CLI proxy for shell commands.

    ## Rule

    Always prefix shell commands with `rtk`.

    Examples:

    ```bash
    rtk git status
    rtk cargo test
    rtk npm run build
    rtk pytest -q
    ```

    ## Meta Commands

    ```bash
    rtk gain            # Token savings analytics
    rtk gain --history  # Recent command savings history
    rtk proxy <cmd>     # Run raw command without filtering
    ```

    ## Verification

    ```bash
    rtk --version
    rtk gain
    which rtk
    ```
  '';

  # Inherit nixpkgs's codex packaging (v8/rusty_v8 archive, webrtc shim,
  # libclang env, postPatch). We just bump version/src/cargoDeps and apply
  # a few quality-of-life patches on top.
  codexRs = pkgs.codex.overrideAttrs (old: {
    inherit src;
    version = codexVersion;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "codex-${codexVersion}-vendor";
      sourceRoot = "source/codex-rs";
      hash = "sha256-S4dsZXfmKvJItL2XYKyxfhqdCMATEG6oPjrtVRwkuYc=";
    };

    # code_mode (0.144+) spawns codex-code-mode-host, resolved as a sibling of
    # the running binary; nixpkgs only builds codex-cli, so build it too.
    cargoBuildFlags = old.cargoBuildFlags ++ [
      "--package"
      "codex-code-mode-host"
    ];

    # Upstream's postPatch strips release profile settings that are too costly
    # for nix builds. Reapply the same intent against 0.141.0's values.
    postPatch = /* sh */ ''
      substituteInPlace $cargoDepsCopy/*/webrtc-sys-*/build.rs \
        --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
      substituteInPlace Cargo.toml \
        --replace-fail 'lto = "thin"' "" \
        --replace-fail 'codegen-units = 4' ""
    '';
  });

  # Reuse the rose-pine .tmTheme already vendored for bat. Codex's `tui.theme`
  # picks it up from $CODEX_HOME/themes/<name>.tmTheme; the file stem becomes
  # the theme name. Diff colors come from the markup.inserted/markup.deleted
  # scopes already present in this file.
  themeName = "rose-pine";
  themeSrc = ../../bat/rose-pine.tmTheme;

  codexConfig = (pkgs.formats.toml { }).generate "codex-config.toml" {
    model = "gpt-5.6-sol";
    personality = "pragmatic";
    model_reasoning_effort = "xhigh";
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    web_search = "live";

    tui = {
      theme = themeName;
      status_line = [
        "model-with-reasoning"
        "project-name"
        "git-branch"
        "weekly-limit"
        "five-hour-limit"
        "context-remaining"
        "fast-mode"
        "permissions"
        "approval-mode"
        "used-tokens"
        "task-progress"
      ];
      status_line_use_colors = true;
    };

    mcp_servers = {
      chrome-devtools = {
        command = "chrome-devtools-mcp";
        args = [
          "--browser-url"
          "http://127.0.0.1:9222"
        ];
      };
      ida-pro-mcp.url = "http://127.0.0.1:13337/mcp";
    };
  };

  # Thin launcher: manage $CODEX_HOME/{RTK.md,AGENTS.md,themes/} on every
  # invocation, then exec the built codex with our default flags. AGENTS.md
  # uses absolute @-refs because codex resolves them relative to CWD, not the
  # AGENTS.md location.
  codex = pkgs.writeScriptBin "codex" /* nu */ ''
    #!${getExe pkgs.nushell} --no-config-file

    def --wrapped main [...args] {
      let codex_home = $env | get --optional "CODEX_HOME" | default ($env.HOME | path join ".codex")
      mkdir $codex_home

      let herdr_integration = do { ^${getExe pkgs.herdr} integration install codex } | complete
      if $herdr_integration.exit_code != 0 {
        error make { msg: $"failed to install Herdr's Codex integration: ($herdr_integration.stderr | str trim)" }
      }

      let claude_md = $env
        | get --optional "XDG_CONFIG_HOME"
        | default ($env.HOME | path join ".config")
        | path join "claude" "CLAUDE.md"

      let rtk_src = "${rtkMd}"
      let rtk_dst = $codex_home | path join "RTK.md"
      let current_rtk = try { ls -l $rtk_dst | get 0.target } catch { null }
      if $current_rtk != $rtk_src {
        rm --force $rtk_dst
        ln -s $rtk_src $rtk_dst
      }

      let theme_src = "${themeSrc}"
      let themes_dir = $codex_home | path join "themes"
      mkdir $themes_dir
      let theme_dst = $themes_dir | path join "${themeName}.tmTheme"
      let current_theme = try { ls -l $theme_dst | get 0.target } catch { null }
      if $current_theme != $theme_src {
        rm --force $theme_dst
        ln -s $theme_src $theme_dst
      }

      let agents_dst = $codex_home | path join "AGENTS.md"
      let desired_agents = [
        $"@($claude_md)"
        ""
        $"@($rtk_dst)"
        ""
      ] | str join "\n"
      let needs_rewrite = try {
        let meta = ls --long $agents_dst | get 0
        if $meta.type == "symlink" {
          true
        } else {
          (open --raw $agents_dst) != $desired_agents
        }
      } catch { true }
      if $needs_rewrite {
        let tmp = $"($agents_dst).tmp"
        $desired_agents | save --force --raw $tmp
        mv $tmp $agents_dst
      }

      let codex_args = [
        --enable code_mode
        --enable code_mode_only
      ]
      exec ${getExe codexRs} ...$codex_args ...$args
    }
  '';

in
{
  options.programs.codex.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    internal = true;
    default = codex;
  };

  config = {
    environment.systemPackages = [ codex ];

    environment.etc."codex/config.toml".source = codexConfig;

    environment.variables.CODEX_HOME = "$XDG_CONFIG_HOME/codex";
  };
}
