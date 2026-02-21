{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  version = "2.1.59";
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

    # Enable hard-disabled slash commands: /btw, /files, /tag
    for anchor, label in [
        (b'name:"btw",description:"Ask a quick side question', b"/btw"),
        (b'name:"files",description:"List all files currently in context"', b"/files"),
        (b'name:"tag",userFacingName', b"/tag"),
    ]:
        pos = data.find(anchor)
        if pos < 0:
            sys.stderr.write(f"{label.decode()}: NOT FOUND\n"); continue
        window = data[pos:pos+500]
        patched = window.replace(b"isEnabled:()=>!1", b"isEnabled:()=>!0", 1)
        data = data[:pos] + patched + data[pos+500:]
        sys.stderr.write(f"{label.decode()}: enabled\n")

    # Bypass gate fn for thinkback (gate fn returns false when DISABLE_TELEMETRY is set)
    data, n = re.subn(
        W + rb'\("tengu_thinkback"\)',
        b'!0||"tengu_thinkback"',
        data,
    )
    sys.stderr.write(f"thinkback: {n} site(s)\n")

    # Enable custom keybindings (gate fn default is false, flip to true)
    data, n = re.subn(
        W + rb'\("tengu_keybinding_customization_release",!1\)',
        lambda m: m[0].replace(b",!1)", b",!0)"),
        data,
    )
    sys.stderr.write(f"keybindings: {n} site(s)\n")

    # Force-enable remote control / bridge feature gate
    data, n = re.subn(
        rb"function (" + W + rb")\(\)\{return " + W + rb'\("tengu_ccr_bridge",!1\)\}',
        lambda m: b"function " + m.group(1) + b"(){return!0}",
        data,
    )
    sys.stderr.write(f"remote-control: {n} site(s)\n")

    # Fix Deno-compile bridge spawn: Deno compiled binaries intercept --flags
    # as V8 flags. Rewrite spawn to go through env(1) which breaks the Deno
    # runtime's flag parsing.
    data, n = re.subn(
        rb"let (" + W + rb")=(" + W + rb")\((" + W + rb")\.execPath,(" + W + rb"),",
        lambda m: b"let " + m[1] + b"=" + m[2] + b'("env",["--",' + m[3] + b".execPath,..." + m[4] + b"],",
        data,
    )
    sys.stderr.write(f"bridge-spawn: {n} site(s)\n")

    # Enable streaming text display (token-by-token instead of waiting for blocks)
    for gate in [b"tengu_streaming_text", b"tengu_immediate_model_command", b"tengu_fgts"]:
        pat = W + rb'\("' + gate + rb'",!1\)'
        data, n = re.subn(pat, lambda m, g=gate: m[0].replace(b",!1)", b",!0)"), data)
        sys.stderr.write(f"{gate.decode()}: {n} site(s)\n")

    # Kill claude-developer-platform bundled skill (~400 tokens/turn dead weight)
    data = data.replace(
        b'name:"claude-developer-platform",description:`',
        b'name:"claude-developer-platform",isEnabled:()=>!1,description:`',
    )
    sys.stderr.write("claude-developer-platform: killed\n")

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
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "claude" ''
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
    '')
  ];

  environment.variables.CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
}
