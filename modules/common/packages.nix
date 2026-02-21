{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  claude-code =
    let
      version = "2.1.50";
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
        import re, sys
        W = rb"[\w$]+"
        data = open(sys.argv[1], "rb").read()

        pat = (rb"let (" + W + rb")=(" + W + rb")\((" + W + rb'),"CLAUDE\.md"\);'
               rb"(" + W + rb")\.push\(\.\.\.(" + W + rb')\(\1,"Project",([^)]+)\)\)')
        def agents(m):
            v, pj, d, a, lf, rest = [m.group(i) for i in range(1, 7)]
            return (b'for(let _f of["CLAUDE.md","AGENTS.md"]){let ' + v + b"=" + pj
                    + b"(" + d + b",_f);" + a + b".push(..." + lf + b"(" + v
                    + b',"Project",' + rest + b"))}")
        data, n = re.subn(pat, agents, data)
        sys.stderr.write(f"AGENTS.md: {n} site(s)\n")

        data = data.replace(
            b'case"macos":return"/Library/Application Support/ClaudeCode"',
            b'case"macos":return"/etc/claude-code"',
        )

        pat = (rb"context_window:\{total_input_tokens:(" + W + rb"\(\)),"
               rb"total_output_tokens:(" + W + rb"\(\)),"
               rb"context_window_size:(" + W + rb"),"
               rb"current_usage:(" + W + rb"),"
               rb"used_percentage:(" + W + rb")\.used,"
               rb"remaining_percentage:\5\.remaining\}")
        rl = re.search(rb"(" + W + rb')=\{status:"allowed",unifiedRateLimitFallbackAvailable:!1,isUsingOverage:!1\}', data)
        m = re.search(pat, data)
        if m and rl:
            ci, co, sz, u, p, r = *[m.group(i) for i in range(1, 6)], rl.group(1)
            data = data.replace(m[0],
                b"context_window:{...(" + u + b"||{}),"
                b"context_window_size:" + sz + b",current_usage:" + u + b","
                b"used_percentage:" + p + b".used,remaining_percentage:" + p + b".remaining,"
                b"rate_limit:" + r + b",s_in:" + ci + b",s_out:" + co + b"}")

        open(sys.argv[1], "wb").write(data)
      '';
    in
    pkgs.writeShellScriptBin "claude" ''
      set -euo pipefail
      export DISABLE_AUTOUPDATER=1
      export DISABLE_INSTALLATION_CHECKS=1
      export USE_BUILTIN_RIPGREP=0
      export PATH="${runtimeDeps}:${pkgs.deno}/bin:$PATH"

      CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/claude-code"
      BIN="$CACHE/claude-${version}"

      if [ ! -x "$BIN" ]; then
        mkdir -p "$CACHE"
        DENO_DIR="$CACHE/.deno"
        export DENO_DIR
        deno cache "npm:@anthropic-ai/claude-code@${version}"
        ${patchScript} "$DENO_DIR/npm/registry.npmjs.org/@anthropic-ai/claude-code/${version}/cli.js"
        deno compile --allow-all --output "$BIN" "npm:@anthropic-ai/claude-code@${version}" 2>&1
        rm -rf "$DENO_DIR"
      fi

      exec "$BIN" "$@"
    '';
in
{
  unfree.allowedNames = [
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    claude-code
    pkgs.cowsay
    pkgs.curl
    pkgs.dig
    pkgs.doggo
    pkgs.dust
    pkgs.dwt1-shell-color-scripts
    pkgs.eza
    pkgs.fastfetch
    pkgs.fd
    pkgs.file
    pkgs.gitui
    pkgs.graphviz
    pkgs.hyperfine
    pkgs.jc
    pkgs.jq
    pkgs.moreutils
    pkgs.openssl
    pkgs.p7zip
    pkgs.pstree
    pkgs.rbw
    pkgs.rsync
    pkgs.sd
    pkgs.timg
    pkgs.tokei
    pkgs.unzip
    pkgs.uutils-coreutils-noprefix
    pkgs.watchman
    pkgs.xh
    pkgs.xxd
    pkgs.yt-dlp
    pkgs.zoxide
  ]
  ++ optionals config.isLinux [
    pkgs.strace
    pkgs.traceroute
    pkgs.usbutils
  ]
  ++ optionals config.isDarwin [
    pkgs.iina
    pkgs.maccy
  ]
  ++ optionals config.isDesktop [
    pkgs.files-to-prompt
    pkgs.go
    pkgs.qbittorrent
    pkgs.sequoia-sq
    pkgs.signal-desktop
    pkgs.wabt
    pkgs.wasmtime
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.thunderbird
  ];

  environment.variables = {
    CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
    GOPATH = "$XDG_DATA_HOME/go";
    GOTELEMETRY = "off";
  };
}
