{
  config,
  lib,
  mkSlopLauncher,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;

  hooksJson = pkgs.writeText "codex-hooks.json" (
    lib.strings.toJSON {
      hooks.PreToolUse = [
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
    }
  );

  codex = mkSlopLauncher {
    name = "codex";
    versionUrl = "https://api.github.com/repos/openai/codex/releases/latest";
    versionParser = "get tag_name | str substring 6..";
    runtimeDeps = [
      pkgs.ripgrep
      pkgs.bubblewrap
    ];
    # NOTE: this preExec asserts declarative ownership of two files in
    # $CODEX_HOME -- AGENTS.md (symlink to shared CLAUDE.md) and hooks.json
    # (symlink to the nix-managed file above). Any non-symlink (or symlink
    # to a different target) gets rm-ed and re-linked on every invocation.
    # All other files in $CODEX_HOME (config.toml, auth.json, history.jsonl,
    # sessions/, memories/, ...) are left alone.
    preExec = /* nu */ ''
      let codex_home = $env | get --optional "CODEX_HOME" | default ($env.HOME | path join ".codex")
      mkdir $codex_home

      let claude_md = $env
        | get --optional "XDG_CONFIG_HOME"
        | default ($env.HOME | path join ".config")
        | path join "claude" "CLAUDE.md"
      let agents_md = $codex_home | path join "AGENTS.md"
      if ($claude_md | path exists) {
        let current = try { ls -l $agents_md | get 0.target } catch { null }
        if $current != $claude_md {
          rm --force $agents_md
          ln -s $claude_md $agents_md
        }
      }

      let hooks_src = "${hooksJson}"
      let hooks_dst = $codex_home | path join "hooks.json"
      let current_hooks = try { ls -l $hooks_dst | get 0.target } catch { null }
      if $current_hooks != $hooks_src {
        rm --force $hooks_dst
        ln -s $hooks_src $hooks_dst
      }
    '';
    fetch = /* nu */ ''
      let arch = match ($nu.os-info.arch | str downcase) {
        "x86_64" | "x64" | "amd64" => "x86_64"
        "aarch64" | "arm64" => "aarch64"
        $arch => { error make { msg: $"unsupported arch: ($arch)" } }
      }

      let target = match ($nu.os-info.name | str downcase) {
        "linux" => $"($arch)-unknown-linux-musl"
        "macos" | "darwin" => $"($arch)-apple-darwin"
        $os => { error make { msg: $"unsupported os: ($os)" } }
      }

      let url = $"https://github.com/openai/codex/releases/download/rust-v($version)/codex-($target).tar.gz"
      let tgz_dir = $cache | path join "tgz"
      mkdir $tgz_dir
      let tgz = $tgz_dir | path join $"codex-($target)-($version).tgz"

      # Download to .tmp + atomic rename so an interrupted run doesn't
      # leave a partial tarball cached forever (sticky-bad).
      if not ($tgz | path exists) {
        let tmp = $"($tgz).tmp"
        print --stderr $"(ansi cyan)fetch:(ansi reset) ($url)"
        http get --raw --max-time 120sec $url | save --force --raw $tmp
        mv $tmp $tgz
      }

      let workdir = $cache | path join $"unpack-($version)"
      rm -rf $workdir
      mkdir $workdir

      ^${getExe pkgs.gnutar} -xzf $tgz -C $workdir
      let extracted = $workdir | path join $"codex-($target)"
      if not ($extracted | path exists) {
        error make { msg: $"fetch: ($extracted) missing after tar extract" }
      }

      mv $extracted $binary_path
      chmod +x $binary_path
      rm -rf $workdir
    '';
  };
in
{
  wrappers.codex = {
    basePackage = codex;
    executables.codex.args.prefix = [
      "--dangerously-bypass-approvals-and-sandbox"
    ];
  };

  environment.systemPackages = [ config.wrappers.codex.finalPackage ];

  environment.variables.CODEX_HOME = "$XDG_CONFIG_HOME/codex";
}
