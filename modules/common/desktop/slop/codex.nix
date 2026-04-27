{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;

  codexSrc = pkgs.fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v0.130.0";
    hash = "sha256-YeUeYbzUMUx0lhIKdtPa8vUYK2Cj1hmbLb68Y80r71o=";
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
  codexRs = pkgs.codex.overrideAttrs (oldAttrs: {
    version = "0.130.0";
    src = codexSrc;
    sourceRoot = "source/codex-rs";

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      name = "codex-0.130.0-vendor";
      src = codexSrc;
      sourceRoot = "source/codex-rs";
      hash = "sha256-cpkj7H/jkKGbfJ92Ty9peqfxibFw2aWWG64tmgeG+2o=";
    };

    # Patches applied to the build source:
    # * codex-gpt55-400k-context: bumps gpt-5.5's `context_window` and
    #   `max_context_window` from 272k to 400k. Two hunks: (1) the bundled
    #   models.json (compiled in via `include_str!`), and (2) a clamp in
    #   `with_config_overrides` so the 400k stays sticky even when
    #   models-manager refreshes its on-disk `models_cache.json` from the
    #   OpenAI `/models` endpoint -- the server still reports 272k for
    #   gpt-5.5 (Codex-product cap), and `try_load_cache` would otherwise
    #   stomp the bundled value with the cached one. The model itself
    #   supports up to 1M tokens via API; 400k is the announced ceiling
    #   for paid Codex plans.
    #
    # Set as `patches` rather than `cargoPatches` because overrideAttrs
    # bypasses buildRustPackage's `patches = cargoPatches ++ patches`
    # concat -- only `patches` reaches stdenv at this layer.
    #
    # Note: nixpkgs's own codex postPatch strips `lto = "fat"` and
    # `codegen-units = 1` on non-Darwin (pkgs/by-name/co/codex/package.nix),
    # so no local fast-release-build patch is needed.
    patches = [
      ./patches/codex-gpt55-400k-context.patch
      ./patches/codex-tui-cursor-jumpiness.patch
    ];

    # postPatch: companion to `codex-tui-cursor-jumpiness.patch`. That
    # patch only carries the renderable.rs hunks from openai/codex#11064;
    # the insert_history.rs hunks are applied here via sed because GNU
    # patch can't match the wrapping-module imports without unacceptable
    # fuzz (the import block was refactored upstream and diverged before
    # #11064 was opened).
    postPatch = (oldAttrs.postPatch or "") + ''
      ${pkgs.gnused}/bin/sed -i \
        -e '/^use crossterm::cursor::MoveDown;/i use crossterm::cursor::Hide;' \
        -e '/^    let writer = terminal\.backend_mut();$/a\
\
    // Hide the terminal cursor while writing wrapped output into scrollback;\
    // otherwise cursor jank (jumps around / blinks randomly) is visible during\
    // streaming and scroll updates.\
    queue!(writer, Hide)?;' \
        tui/src/insert_history.rs
    '';

    # 0.125 added codex-v8-poc as a workspace member (a "future V8
    # experiments" placeholder). Default `cargo build --release` builds
    # all workspace bins, dragging in v8-poc and a 200MB rusty_v8
    # archive we do not need. Limit the build to codex-cli.
    cargoBuildFlags = [
      "--package"
      "codex-cli"
    ];
  });

  # Thin launcher: manage $CODEX_HOME/{RTK.md,AGENTS.md} on every invocation,
  # then exec the built codex with our default flags. AGENTS.md uses
  # absolute @-refs because codex resolves them relative to CWD, not the
  # AGENTS.md location.
  codex = pkgs.writeScriptBin "codex" /* nu */ ''
    #!${getExe pkgs.nushell} --no-config-file

    def --wrapped main [...args] {
      let codex_home = $env | get --optional "CODEX_HOME" | default ($env.HOME | path join ".codex")
      mkdir $codex_home

      # Codex hooks reject updatedInput so rtk-rewrite.sh can't work here;
      # clean up any leftover from the aborted hook approach.
      let stale_hooks = $codex_home | path join "hooks.json"
      if ($stale_hooks | path exists) { rm --force $stale_hooks }

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

      exec ${getExe codexRs} --dangerously-bypass-approvals-and-sandbox --enable code_mode --enable code_mode_only --enable goals ...$args
    }
  '';
in
{
  environment.systemPackages = [ codex ];

  environment.variables.CODEX_HOME = "$XDG_CONFIG_HOME/codex";
}
