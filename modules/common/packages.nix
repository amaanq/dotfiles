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
      version = "2.1.37";
      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}";
      sources = {
        x86_64-linux = {
          url = "${baseUrl}/linux-x64/claude";
          hash = "sha256-+Wek0G4WoyQ2tjKeLb7UWan6TTTwdjWh+ycbdPcGyR8=";
        };
        aarch64-linux = {
          url = "${baseUrl}/linux-arm64/claude";
          hash = "sha256-1yXMcwYPQAp6wDp2mWk5fa7J1BHb1bHHux+mBCe/ZX4=";
        };
        aarch64-darwin = {
          url = "${baseUrl}/darwin-arm64/claude";
          hash = "sha256-AO0Qr7elYkQHc94xKEVozpwzOF1506kSoSryYq79Ew4=";
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

                # Patch thinking spinner to always say "Redeeming"
                ${pkgs.python3}/bin/python3 -c "
        import sys
        path = sys.argv[1]
        data = open(path, 'rb').read()
        old = b'function U4D(){let \x24=GB().spinnerVerbs;if(!\x24)return i0H;if(\x24.mode===\x22replace\x22)return \x24.verbs.length>0?\x24.verbs:i0H;return[...i0H,...\x24.verbs]}'
        new = b'function U4D(){' + b' '*105 + b'return[\x22Redeeming\x22]}'
        assert len(old) == len(new), f'len mismatch: {len(old)} vs {len(new)}'
        assert data.count(old) > 0, 'spinner pattern not found in binary'
        data = data.replace(old, new)
        open(path, 'wb').write(data)
        " $out/bin/.claude-unwrapped

                # Add AGENTS.md support alongside CLAUDE.md (whole-function replacement of zRI)
                ${pkgs.python3}/bin/python3 -c "
        import sys; path = sys.argv[1]; data = open(path, 'rb').read()
        old = b'function zRI(H,\x24,A){let L=[];if(HF(\x22projectSettings\x22)){let B=Sf.join(H,\x22CLAUDE.md\x22);L.push(...jT(B,\x22Project\x22,A,!1));let f=Sf.join(H,\x22.claude\x22,\x22CLAUDE.md\x22);L.push(...jT(f,\x22Project\x22,A,!1))}if(HF(\x22localSettings\x22)){let B=Sf.join(H,\x22CLAUDE.local.md\x22);L.push(...jT(B,\x22Local\x22,A,!1))}let I=Sf.join(H,\x22.claude\x22,\x22rules\x22),D=new Set(A);L.push(...EBH({rulesDir:I,type:\x22Project\x22,processedPaths:D,includeExternal:!1,conditionalRule:!1})),L.push(...KF\x24(\x24,I,\x22Project\x22,A,!1));for(let B of D)A.add(B);return L}'
        new = b'function zRI(H,\x24,A){let L=[];if(HF(\x22projectSettings\x22)){var B;for(B of[\x22CLAUDE.md\x22,\x22AGENTS.md\x22])L.push(...jT(Sf.join(H,B),\x22Project\x22,A,0));L.push(...jT(Sf.join(H,\x22.claude\x22,\x22CLAUDE.md\x22),\x22Project\x22,A,0))}if(HF(\x22localSettings\x22))L.push(...jT(Sf.join(H,\x22CLAUDE.local.md\x22),\x22Local\x22,A,0));let I=Sf.join(H,\x22.claude\x22,\x22rules\x22),D=new Set(A);L.push(...EBH({rulesDir:I,type:\x22Project\x22,processedPaths:D,includeExternal:0,conditionalRule:0})),L.push(...KF\x24(\x24,I,\x22Project\x22,A,0));D.forEach(B=>A.add(B));return L  }'
        assert len(old) == len(new), f'len mismatch: {len(old)} vs {len(new)}'
        assert data.count(old) > 0, 'zRI pattern not found in binary'
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
