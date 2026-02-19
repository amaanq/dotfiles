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
      version = "2.1.47";
      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}";
      sources = {
        x86_64-linux = {
          url = "${baseUrl}/linux-x64/claude";
          hash = "sha256-nEi95nvaJ01lw9ZdpPeOIaRYznIqiVXtzCctMsmMdKM=";
        };
        aarch64-linux = {
          url = "${baseUrl}/linux-arm64/claude";
          hash = "sha256-klXTMNsZNT1zs5dbC8Lrrd0c8AKmL6Fblaa7/sipvhg=";
        };
        aarch64-darwin = {
          url = "${baseUrl}/darwin-arm64/claude";
          hash = "sha256-c3lebY8KpOB9jyDTUeD4TlFdss5ztpdwZQvD1dWC73M=";
        };
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "claude-code";
      inherit version;
      src = pkgs.fetchurl sources.${pkgs.stdenv.hostPlatform.system};
      dontUnpack = true;
      dontStrip = true;
      nativeBuildInputs = [
        pkgs.makeBinaryWrapper
      ]
      ++ optionals pkgs.stdenv.hostPlatform.isElf [ pkgs.autoPatchelfHook ];
      installPhase = ''
                install -Dm755 $src $out/bin/.claude-unwrapped

                # Add AGENTS.md support alongside CLAUDE.md (version-agnostic)
                ${pkgs.python3}/bin/python3 -c "
        import re, sys; path = sys.argv[1]; data = open(path, 'rb').read()
        if b'\x22AGENTS.md\x22' in data:
            sys.stderr.write('AGENTS.md already supported natively, skipping\n'); sys.exit(0)
        ID = rb'[\w\x24]+'
        old = None
        for m in re.finditer(rb'function (' + ID + rb')\((' + ID + rb'),(' + ID + rb'),(' + ID + rb')\)\{', data):
            depth = 0; i = m.end() - 1; fe = None
            while i < len(data) and i < m.start() + 2000:
                if data[i:i+1] == b'{': depth += 1
                elif data[i:i+1] == b'}':
                    depth -= 1
                    if depth == 0: fe = i + 1; break
                i += 1
            if fe is None: continue
            body = data[m.start():fe]
            if b'\x22projectSettings\x22' in body and b'\x22CLAUDE.md\x22' in body and b'\x22localSettings\x22' in body:
                old = body; break
        if old is None:
            sys.stderr.write('WARNING: AGENTS.md function not found, skipping\n'); sys.exit(0)
        fn, p1, p2, p3 = m.group(1), m.group(2), m.group(3), m.group(4)
        arr = re.search(rb'let (' + ID + rb')=\[\]', old).group(1)
        hf = re.search(rb'(' + ID + rb')\(\x22projectSettings\x22\)', old).group(1)
        pm = re.search(rb'(' + ID + rb')\.join\(' + re.escape(p1) + rb',\x22CLAUDE\.md\x22\)', old).group(1)
        lf = re.search(rb'\.\.\.(' + ID + rb')\([^,]+,\x22Project\x22,' + re.escape(p3) + rb',!1\)', old).group(1)
        rf = re.search(rb'\.\.\.(' + ID + rb')\(\{rulesDir:', old).group(1)
        kf = re.search(rb'\.\.\.(' + ID + rb')\(' + re.escape(p2) + rb',', old).group(1)
        vv = re.search(rb'let (' + ID + rb')=' + re.escape(pm) + rb'\.join\(' + re.escape(p1) + rb',\x22\.claude\x22,\x22rules\x22\),(' + ID + rb')=new Set\(' + re.escape(p3) + rb'\)', old)
        v4, v5 = vv.group(1), vv.group(2)
        v1 = re.search(rb'let (' + ID + rb')=' + re.escape(pm) + rb'\.join\(' + re.escape(p1) + rb',\x22CLAUDE\.md\x22\)', old).group(1)
        nb = (b'function ' + fn + b'(' + p1 + b',' + p2 + b',' + p3 + b'){let ' + arr + b'=[];if(' + hf + b'(\x22projectSettings\x22)){var ' + v1 + b';for(' + v1 + b' of[\x22CLAUDE.md\x22,\x22AGENTS.md\x22])' + arr + b'.push(...' + lf + b'(' + pm + b'.join(' + p1 + b',' + v1 + b'),\x22Project\x22,' + p3 + b',0));' + arr + b'.push(...' + lf + b'(' + pm + b'.join(' + p1 + b',\x22.claude\x22,\x22CLAUDE.md\x22),\x22Project\x22,' + p3 + b',0))}if(' + hf + b'(\x22localSettings\x22))' + arr + b'.push(...' + lf + b'(' + pm + b'.join(' + p1 + b',\x22CLAUDE.local.md\x22),\x22Local\x22,' + p3 + b',0));let ' + v4 + b'=' + pm + b'.join(' + p1 + b',\x22.claude\x22,\x22rules\x22),' + v5 + b'=new Set(' + p3 + b');' + arr + b'.push(...' + rf + b'({rulesDir:' + v4 + b',type:\x22Project\x22,processedPaths:' + v5 + b',includeExternal:0,conditionalRule:0})),' + arr + b'.push(...' + kf + b'(' + p2 + b',' + v4 + b',\x22Project\x22,' + p3 + b',0));' + v5 + b'.forEach(' + v1 + b'=>' + p3 + b'.add(' + v1 + b'));return ' + arr)
        pad = len(old) - len(nb) - 1
        assert pad >= 0, f'AGENTS.md: replacement too long by {-pad}'
        new = nb + b' ' * pad + b'}'
        assert len(old) == len(new), f'len mismatch: {len(old)} vs {len(new)}'
        data = data.replace(old, new)
        open(path, 'wb').write(data)
        " $out/bin/.claude-unwrapped

                # Patch managed settings path on macOS: /Library/Application Support/ClaudeCode -> /etc/claude-code
                ${pkgs.python3}/bin/python3 -c "
        import sys; path = sys.argv[1]; data = open(path, 'rb').read()
        old = b'case\x22macos\x22:return\x22/Library/Application Support/ClaudeCode\x22'
        new_val = b'case\x22macos\x22:return\x22/etc/claude-code\x22'
        pad = len(old) - len(new_val)
        assert pad >= 0, f'managed settings path: replacement too long by {-pad}'
        new = new_val + b' ' * pad
        assert len(old) == len(new)
        data = data.replace(old, new)
        open(path, 'wb').write(data)
        " $out/bin/.claude-unwrapped

                # Fix status line: show current context tokens + rate limit state
                ${pkgs.python3}/bin/python3 -c "
        import re, sys; path = sys.argv[1]; data = open(path, 'rb').read()
        I = rb'[\w\x24]+'
        pat = (rb'context_window:\{total_input_tokens:(' + I + rb'\(\)),'
            rb'total_output_tokens:(' + I + rb'\(\)),'
            rb'context_window_size:(' + I + rb'),'
            rb'current_usage:(' + I + rb'),'
            rb'used_percentage:(' + I + rb')\.used,'
            rb'remaining_percentage:\5\.remaining\}')
        m = re.search(pat, data)
        assert m, 'context_window pattern not found'
        old = m.group(0)
        ci, co, s, u, p = [m.group(i) for i in range(1,6)]
        rl = re.search(rb'([\w\x24]+)=\{status:\x22allowed\x22,unifiedRateLimitFallbackAvailable:!1,isUsingOverage:!1\}', data)
        assert rl, 'rate limit state var not found'
        r = rl.group(1)
        body = (b'context_window:{...(' + u + b'||{}),'
            b'context_window_size:' + s + b','
            b'current_usage:' + u + b','
            b'used_percentage:' + p + b'.used,'
            b'remaining_percentage:' + p + b'.remaining,'
            b'rate_limit:' + r + b','
            b's_in:' + ci + b',s_out:' + co)
        pad = len(old) - len(body) - 1
        assert pad >= 0, f'status line: replacement too long by {-pad}'
        new = body + b' ' * pad + b'}'
        assert len(old) == len(new)
        data = data.replace(old, new)
        open(path, 'wb').write(data)
        " $out/bin/.claude-unwrapped

                makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
                  --set DISABLE_AUTOUPDATER 1 \
                  --set DISABLE_INSTALLATION_CHECKS 1 \
                  --set USE_BUILTIN_RIPGREP 0 \
                  --prefix PATH : ${
                    lib.makeBinPath (
                      [
                        pkgs.procps
                        pkgs.ripgrep
                      ]
                      ++ optionals pkgs.stdenv.hostPlatform.isLinux [
                        pkgs.bubblewrap
                        pkgs.socat
                      ]
                    )
                  }
      '';
      meta = {
        mainProgram = "claude";
        platforms = builtins.attrNames sources;
      };
    };
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
