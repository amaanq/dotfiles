{
  config,
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

in
{
  unfree.allowedNames = [
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    chrome-devtools-mcp
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
  ];
}
