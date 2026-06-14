{
  config,
  lib,
  mkSlopLauncher,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe getExe';
  inherit (lib.strings) toJSON;

  # Bun → Node shim prepended to cli.cjs. node:timers fixes
  # `setTimeout(...).unref()`. TTY readable→data swap is in the patcher
  # (a global Deno.stdin pump races the bundle's own /dev/tty reader).
  bunShim = /* js */ ''
    (() => {
      if (typeof globalThis.Bun !== "undefined") return;

      const _nt = require("node:timers");
      globalThis.setTimeout = _nt.setTimeout;
      globalThis.setInterval = _nt.setInterval;
      globalThis.clearTimeout = _nt.clearTimeout;
      globalThis.clearInterval = _nt.clearInterval;
      globalThis.setImmediate = _nt.setImmediate;
      globalThis.clearImmediate = _nt.clearImmediate;

      const sw = require("string-width");
      const sa = require("strip-ansi");
      const wa = require("wrap-ansi");
      const sv = require("semver");
      const ya = require("yaml");
      const cp = require("child_process");
      const fs = require("fs");
      const path = require("path");
      const crypto = require("crypto");
      const net = require("net");

      function bunHash(input) {
        const buf = Buffer.isBuffer(input)
          ? input
          : Buffer.from(typeof input === "string" ? input : String(input));
        return crypto.createHash("sha1").update(buf).digest().readBigUInt64LE(0);
      }

      function bunMapStdio(s) {
        if (s === "ignore" || s === "inherit" || s === "pipe") return s;
        if (s == null) return "pipe";
        return s;
      }

      let _ptyMod = null;
      function bunPty() {
        if (!_ptyMod) _ptyMod = require("@homebridge/node-pty-prebuilt-multiarch");
        return _ptyMod;
      }

      const _SIGNAMES = {
        1: "SIGHUP", 2: "SIGINT", 3: "SIGQUIT", 6: "SIGABRT",
        9: "SIGKILL", 13: "SIGPIPE", 14: "SIGALRM", 15: "SIGTERM",
      };

      class BunTerminal {
        constructor(opts) {
          opts = opts || {};
          this.cols = opts.cols || 80;
          this.rows = opts.rows || 24;
          this._dataCb = opts.data;
          this._pty = null;
          this._disposed = false;
        }
        _attach(pty) {
          if (this._disposed) { try { pty.kill(); } catch {} return; }
          this._pty = pty;
          pty.onData(d => {
            if (this._disposed) return;
            try { this._dataCb(this, Buffer.from(d, "utf8")); } catch {}
          });
        }
        write(buf) {
          if (!this._pty || this._disposed) return;
          try { this._pty.write(Buffer.isBuffer(buf) ? buf : Buffer.from(buf)); } catch {}
        }
        resize(c, r) {
          this.cols = c; this.rows = r;
          if (this._pty && !this._disposed) {
            try { this._pty.resize(c, r); } catch {}
          }
        }
        close() {
          if (this._disposed) return;
          this._disposed = true;
          if (this._pty) { try { this._pty.kill(); } catch {} }
        }
      }

      function bunSpawnTerminal(cmd, opts) {
        const [bin, ...args] = cmd;
        const T = opts.terminal;
        const p = bunPty().spawn(bin, args, {
          name: "xterm-256color",
          cols: T.cols,
          rows: T.rows,
          cwd: opts.cwd || process.cwd(),
          env: opts.env || process.env,
        });
        T._attach(p);
        let _sig;
        const exited = new Promise(r => {
          p.onExit(({ exitCode, signal }) => {
            if (signal != null && signal !== 0) {
              _sig = _SIGNAMES[signal] || ("SIG" + signal);
            }
            r(exitCode == null ? 1 : exitCode);
          });
        });
        return {
          pid: p.pid,
          exited,
          get signalCode() { return _sig; },
          kill(s) { try { p.kill(typeof s === "string" ? s : undefined); } catch {} },
        };
      }

      function bunSpawn(cmd, opts) {
        opts = opts || {};
        if (opts.terminal) return bunSpawnTerminal(cmd, opts);
        const [bin, ...args] = cmd;
        let stdio;
        if (Array.isArray(opts.stdio)) {
          stdio = opts.stdio.map(bunMapStdio);
        } else {
          stdio = [
            bunMapStdio(opts.stdin),
            bunMapStdio(opts.stdout),
            bunMapStdio(opts.stderr),
          ];
        }
        const child = cp.spawn(bin, args, {
          cwd: opts.cwd,
          env: opts.env || process.env,
          stdio,
          argv0: opts.argv0,
          detached: !!opts.detached,
          windowsHide: opts.windowsHide !== !1,
          uid: opts.uid,
          gid: opts.gid,
        });
        const exited = new Promise(r => child.on("exit", c => r(c == null ? 1 : c)));
        return {
          pid: child.pid,
          stdin: child.stdin,
          stdout: child.stdout,
          stderr: child.stderr,
          exitCode: null,
          killed: false,
          kill(s) { try { child.kill(s); } catch {} this.killed = true; },
          async wait() { return await exited; },
          exited,
          unref() { try { child.unref(); } catch {} return this; },
          ref() { try { child.ref(); } catch {} return this; },
        };
      }

      function bunListen(opts) {
        const h = opts.socket || {};
        const server = net.createServer(s => {
          s.data = undefined;
          if (h.open) try { h.open(s); } catch {}
          s.on("data", d => h.data && h.data(s, d));
          s.on("close", () => h.close && h.close(s));
          s.on("error", e => h.error && h.error(s, e));
        });
        server.listen(opts.port || 0, opts.hostname || "127.0.0.1");
        return server;
      }

      class BunTranspiler {
        constructor(o) { this.opts = o; }
        transformSync(s) { return s; }
      }

      globalThis.Bun = {
        version: "1.3.13",
        embeddedFiles: [],
        Terminal: BunTerminal,
        stringWidth: (s, o) => sw(String(s || ""), o),
        stripANSI: s => sa(String(s || "")),
        wrapAnsi: (s, w, o) => wa(String(s || ""), w, o),
        semver: {
          satisfies: (a, b) => sv.satisfies(a, b),
          order: (a, b) => sv.compare(a, b),
        },
        hash: bunHash,
        which(cmd) {
          const dirs = (process.env.PATH || "").split(path.delimiter);
          for (const d of dirs) {
            const f = path.join(d, cmd);
            try { fs.accessSync(f, fs.constants.X_OK); return f; } catch {}
          }
          return null;
        },
        spawn: bunSpawn,
        listen: bunListen,
        YAML: {
          parse: s => ya.parse(s),
          stringify: (o, r, i) => ya.stringify(o, r, i),
        },
        Transpiler: BunTranspiler,
        generateHeapSnapshot: () => new ArrayBuffer(0),
        gc: () => {},
      };
    })();
  '';

  statusLine = pkgs.writeScriptBin "claude-code-statusline" /* nu */ ''
    #!${getExe pkgs.nushell}

    def format-duration [ms: int] {
        let total_s = $ms // 1000
        let h = $total_s // 3600
        let m = ($total_s mod 3600) // 60
        let s = $total_s mod 60
        if $h > 0 {
            $"($h)h($m | fill -a r -w 2 -c '0')m($s | fill -a r -w 2 -c '0')s"
        } else if $m > 0 {
            $"($m)m($s | fill -a r -w 2 -c '0')s"
        } else {
            $"($s)s"
        }
    }

    def color-for-pct [pct: number] {
        let pct_int = $pct | math floor | into int
        if $pct_int >= 80 {
            "\e[31m"
        } else if $pct_int >= 50 {
            "\e[33m"
        } else {
            "\e[32m"
        }
    }

    def format-rate-limits [input: record] {
        let session_pct = try { $input | get rate_limits.five_hour.used_percentage } catch { null }
        let week_pct = try { $input | get rate_limits.seven_day.used_percentage } catch { null }

        let session_part = if $session_pct != null {
            let c = color-for-pct $session_pct
            let v = $session_pct | math round --precision 0 | into int
            $"session: ($c)($v)%\e[0m"
        } else { "" }
        let week_part = if $week_pct != null {
            let c = color-for-pct $week_pct
            let v = $week_pct | math round --precision 0 | into int
            $"week: ($c)($v)%\e[0m"
        } else { "" }

        [$session_part $week_part] | where {|x| $x | is-not-empty} | str join " "
    }

    def get-jj-info [] {
        let root_result = do { jj root } | complete
        if $root_result.exit_code != 0 { return "" }

        let bookmark = (do { jj log -r @ --no-graph -T 'bookmarks.map(|b| b.name()).join(", ")' } | complete | get stdout | str trim)
        let change = (do { jj log -r @ --no-graph -T 'change_id.shortest(8)' } | complete | get stdout | str trim)
        let is_empty_str = (do { jj log -r @ --no-graph -T 'empty' } | complete | get stdout | str trim)
        let dirty = if $is_empty_str == "false" { "*" } else { "" }
        let has_conflict = (do { jj log -r @ --no-graph -T 'conflict' } | complete | get stdout | str trim)
        let conflict_marker = if $has_conflict == "true" { " \e[31m!conflict\e[0m" } else { "" }

        let ref_part = if ($bookmark | is-not-empty) {
            $" | \e[36m($bookmark)($dirty)\e[0m"
        } else if ($change | is-not-empty) {
            $" | \e[35m($change)($dirty)\e[0m"
        } else { "" }

        $"($ref_part)($conflict_marker)"
    }

    # --- Main ---
    let input = (^cat | from json)

    let usage_info = format-rate-limits $input

    let model_name = ($input | get model?.display_name? | default ($input | get model?.id? | default "unknown"))
    let used_pct = ($input | get context_window?.used_percentage? | default null)
    let total_cost = ($input | get cost?.total_cost_usd? | default 0)
    let total_input = ($input | get context_window?.s_in? | default ($input | get context_window?.total_input_tokens? | default 0))
    let total_output = ($input | get context_window?.s_out? | default ($input | get context_window?.total_output_tokens? | default 0))
    let duration_ms = ($input | get cost?.total_duration_ms? | default 0)
    let api_duration_ms = ($input | get cost?.total_api_duration_ms? | default 0)
    let lines_added = ($input | get cost?.total_lines_added? | default 0)
    let lines_removed = ($input | get cost?.total_lines_removed? | default 0)
    let exceeds_200k = ($input | get exceeds_200k_tokens? | default false)

    let cache_read = ($input | get context_window?.cache_read_tokens? | default 0)
    let cache_create = ($input | get context_window?.cache_creation_tokens? | default 0)

    let total_tokens = $total_input + $total_output

    def format-tokens [n: int] {
        if $n >= 1_000_000 {
            $"($n / 1_000_000.0 | math round --precision 1)M"
        } else if $n >= 1_000 {
            $"($n / 1_000.0 | math round --precision 1)k"
        } else {
            $"($n)"
        }
    }

    let in_display = (format-tokens ($total_input | into int))
    let out_display = (format-tokens ($total_output | into int))
    let tok_display = $"($in_display)/($out_display)"

    let cache_total = $cache_read + $cache_create
    let cache_display = if $cache_total > 0 {
        let cache_pct = ($cache_read * 100 / $cache_total | math round --precision 0 | into int)
        let cache_color = if $cache_pct >= 70 {
            "\e[32m"
        } else if $cache_pct >= 40 {
            "\e[33m"
        } else {
            "\e[31m"
        }
        $" cache:($cache_color)($cache_pct)%\e[0m"
    } else { "" }

    let context_display = if $used_pct != null {
        let color = color-for-pct $used_pct
        let pct_str = $used_pct | math round --precision 1
        $"($color)($pct_str)%\e[0m"
    } else { "--" }

    let cost_cents = ($total_cost * 100 | math round | into int)
    let cost_dollars = $cost_cents // 100
    let cost_frac = ($cost_cents mod 100 | math abs | into string | fill -a r -w 2 -c '0')
    let cost_display = $"$($cost_dollars).($cost_frac)"
    let elapsed_display = (format-duration ($duration_ms | into int))
    let wait_display = (format-duration ($api_duration_ms | into int))
    let churn_display = $"\e[32m+($lines_added)\e[0m/\e[31m-($lines_removed)\e[0m"
    let marker_200k = if $exceeds_200k { " | \e[31m!200k\e[0m" } else { "" }
    def format-cwd [dir: string] {
        if ($dir | is-empty) { return "" }
        let jj_root = try { do { cd $dir; jj workspace root } | complete } catch { {exit_code: 1, stdout: ""} }
        if $jj_root.exit_code == 0 {
            let root = ($jj_root.stdout | str trim)
            let home = ($env.HOME? | default "")
            let root_display = if ($home | is-not-empty) and ($root | str starts-with $home) {
                let rel = ($root | str replace $home "" | str trim -l -c '/')
                $"~/($rel)"
            } else {
                $root
            }
            let root_parts = ($root_display | split row "/")
            let base = if ($root_parts | length) <= 5 {
                $root_display
            } else {
                let tail = ($root_parts | last 5 | str join "/")
                $"…/($tail)"
            }
            let subpath = if ($dir | str starts-with $root) {
                $dir | str replace $root "" | str trim -l -c '/'
            } else { "" }
            if ($subpath | is-not-empty) {
                $"\e[36m($base)\e[0m → \e[34m($subpath)\e[0m"
            } else {
                $"\e[36m($base)\e[0m"
            }
        } else {
            let home = ($env.HOME? | default "")
            let display = if ($home | is-not-empty) and ($dir | str starts-with $home) {
                let rel = ($dir | str replace $home "" | str trim -l -c '/')
                $"~/($rel)"
            } else {
                $dir
            }
            let parts = ($display | split row "/")
            let shortened = if ($parts | length) <= 5 {
                $display
            } else {
                let tail = ($parts | last 5 | str join "/")
                $"…/($tail)"
            }
            $shortened
        }
    }

    let cwd_raw = ($input | get workspace?.current_dir? | default "")
    let cwd_display = if ($cwd_raw | is-not-empty) {
        let formatted = (format-cwd $cwd_raw)
        $" | ($formatted)"
    } else { "" }
    let jj_info = get-jj-info
    let quota_section = if ($usage_info | is-not-empty) {
        " | (usage) " + $usage_info
    } else { "" }

    print -n $"($model_name) | Ctx: ($context_display) | ($tok_display)($cache_display) | ($cost_display) | t:($elapsed_display) w:($wait_display) | ($churn_display)($marker_200k)($jj_info)($quota_section)($cwd_display)"
  '';

  # Lifts cli.js source out of the bun --compile --bytecode SEA ELF that
  # the npm package has shipped since 2.1.113.
  lift = pkgs.writeScriptBin "lift-claude-bun" /* py */ ''
    #!${getExe pkgs.python3}
    from __future__ import annotations

    import sys
    from pathlib import Path

    # Skip .rodata/.text — they contain `// @bun` string literals that confuse
    # the scanner. First real module was at ~0xd333ec8 in 2.1.113.
    SCAN_FROM: int = 0x6000000

    HEADERS: list[bytes] = [
        b"// @bun @bytecode @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
        b"// @bun @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
    ]

    CJS_OPEN: bytes = b"(function(exports, require, module, __filename, __dirname) {"
    CJS_END: bytes = b"})\n\x00"


    def find_main_module(data: bytes) -> tuple[int, int]:
        # 2.1.117+ emits cli.js twice: once as @bytecode with the V8 parse
        # cache interleaved before the terminator, and once as clean source.
        # Pick the first header whose terminator precedes the next header.
        headers: list[tuple[int, int]] = []
        for header in HEADERS:
            p: int = SCAN_FROM
            while True:
                p = data.find(header, p)
                if p < 0:
                    break
                headers.append((p, len(header)))
                p += 1

        if not headers:
            sys.exit("lift: no bun CJS module header found past 0x6000000")

        headers.sort()
        boundaries: list[int] = [p for p, _ in headers] + [len(data)]

        for idx, (start, _) in enumerate(headers):
            next_header: int = boundaries[idx + 1]
            end: int = data.find(CJS_END, start, next_header)
            if end >= 0:
                return start, end + 3  # include })\n, exclude trailing NUL

        sys.exit("lift: could not find module terminator (})\\n\\x00)")


    def unwrap(mod: bytes) -> bytes:
        nl = mod.find(b"\n")
        if nl < 0:
            sys.exit("lift: module has no header newline")
        body = mod[nl + 1 :]
        if not body.startswith(CJS_OPEN):
            sys.exit("lift: module does not open with expected CJS wrapper")
        body = body[len(CJS_OPEN) :]
        if body.endswith(b"})\n"):
            body = body[:-3]
        elif body.endswith(b"})"):
            body = body[:-2]
        else:
            sys.exit("lift: module does not end with `})` wrapper close")
        return body


    def main() -> None:
        if len(sys.argv) != 3:
            sys.exit("usage: lift-claude-bun <claude-binary> <output.cjs>")

        binary = Path(sys.argv[1])
        output = Path(sys.argv[2])

        data = binary.read_bytes()
        start, end = find_main_module(data)
        body = unwrap(data[start:end])

        if b"Anthropic" not in body[:4096]:
            sys.exit("lift: extracted body is missing Anthropic banner — layout changed?")

        output.write_bytes(body)
        sys.stderr.write(
            f"lifted {len(body):,} bytes from {binary.name} "
            f"(module @ {start:#x}..{end:#x}) -> {output}\n"
        )


    if __name__ == "__main__":
        main()
  '';

  patch = pkgs.writeScriptBin "patch-claude-code-src" /* py */ ''
    #!${getExe pkgs.python3}
    from __future__ import annotations

    import re
    import sys
    from collections.abc import Callable
    from pathlib import Path
    from typing import Union

    type Replacement = Union[bytes, Callable[[re.Match[bytes]], bytes]]

    W: bytes = rb"[\w$]+"
    # Qualified name: matches `FN` and `NS.FN`. Bun's bundler emits member-style
    # calls for path/spawn helpers since 2.1.113.
    Q: bytes = rb"[\w$]+(?:\.[\w$]+)*"
    data: bytes = Path(sys.argv[1]).read_bytes()

    SEARCH_WINDOW: int = 500


    def log(msg: str) -> None:
        sys.stderr.write(msg + "\n")


    def patch(label: str, pattern: bytes, replacement: Replacement) -> None:
        global data
        data, n = re.subn(pattern, replacement, data)
        log(f"{label} ({n})")


    def replace(label: str, old: bytes, new: bytes) -> None:
        global data
        n: int = data.count(old)
        if n == 0:
            log(f"{label}: NOT FOUND")
            return
        data = data.replace(old, new)
        log(f"{label} ({n})")


    def enable_gates(gates: list[tuple[bytes, str]]) -> None:
        """Force our feature gates on via the Ikt() override map.

        DISABLE_TELEMETRY=1 stops GrowthBook from resolving, so gates fall back
        to a hardcoded value. The sync resolver ct(e,t) returns the call-site
        default (so flipping a `,!1)` default would work for it), but the async
        resolver eB(e) returns a flat false no matter the default — and
        ccr_bridge / harbor / ccr_bundle_seed_enabled are read through eB. All
        resolvers consult the override map Ikt() first, before any telemetry
        check or exposure logging, and Ikt only ever returns null in normal
        operation, so injecting our gates there enables the sync and async paths
        uniformly with no telemetry side effects. The object is memoized on
        globalThis since Ikt() is on the hot path of every gate lookup.
        """
        global data
        for g, lbl in gates:
            if b'"' + g + b'"' not in data:
                log(f"  gate gone from bundle: {lbl} [{g.decode()}]")
        override: bytes = b"{" + b",".join(b'"' + g + b'":!0' for g, _ in gates) + b"}"
        data, n = re.subn(
            rb"function (" + W + rb")\(\)\{if\(!(" + W + rb")\)\2=!0;return (" + W + rb")\}",
            lambda m: (
                b"function " + m[1] + b"(){if(!" + m[2] + b")" + m[2] + b"=!0;return "
                + m[3] + b"||(globalThis.__ccg??=" + override + b")}"
            ),
            data,
        )
        log(f"gate override map: {len(gates)} gates injected at {n} site(s)")


    # --- AGENTS.md loader ---
    # Also load AGENTS.md from the same dirs as CLAUDE.md.

    agents_pat: bytes = (
        rb"let (" + W + rb")=(" + Q + rb")\((" + W + rb'),"CLAUDE\.md"\);'
        rb"(" + W + rb")\.push\(\.\.\.await (" + W + rb")\(\1,\"Project\",(" + W + rb"),(" + W + rb")\)\)"
    )


    def agents_repl(m: re.Match[bytes]) -> bytes:
        var, join_fn, dir_, arr, load_fn, arg, flag = [m.group(i) for i in range(1, 8)]
        return (
            b'for(let _f of["CLAUDE.md","AGENTS.md"]){let '
            + var + b"=" + join_fn + b"(" + dir_ + b",_f);"
            + arr + b".push(...await " + load_fn + b"(" + var + b',"Project",' + arg + b"," + flag + b"))}"
        )


    patch("agents.md loader", agents_pat, agents_repl)

    # --- macOS config path ---

    replace(
        "macOS config path",
        b'case"macos":return"/Library/Application Support/ClaudeCode"',
        b'case"macos":return"/etc/claude-code"',
    )

    # --- Enable hard-disabled slash commands ---

    slash_commands: list[tuple[bytes, str]] = [
        (b'name:"btw",description:"Ask a quick side question', "/btw"),
    ]

    for anchor, label in slash_commands:
        pos: int = data.find(anchor)
        if pos < 0:
            log(f"slash command {label}: NOT FOUND")
            continue
        window: bytes = data[pos : pos + SEARCH_WINDOW]
        patched: bytes = window.replace(b"isEnabled:()=>!1", b"isEnabled:()=>!0", 1)
        if patched == window:
            log(f"slash command {label}: isEnabled not found in window")
            continue
        data = data[:pos] + patched + data[pos + SEARCH_WINDOW :]
        log(f"slash command {label}: enabled")

    # --- Restore 1h prompt cache TTL when telemetry is off ---
    # https://github.com/anthropics/claude-code/issues/45381
    # Widen the GrowthBook allowlist default to ["*"] so batch agents and
    # less-common query sources also get 1h cache_control.

    patch(
        "1h prompt cache TTL fallback",
        rb'(' + W + rb')\("tengu_prompt_cache_1h_config",\{allowlist:\[[^\]]+\]\}\)\.allowlist\?\?\[\]',
        lambda m: m[1] + b'("tengu_prompt_cache_1h_config",{allowlist:["*"]}).allowlist??[]',
    )

    # --- stdin: readable → data (Deno TTY compat) ---
    # Deno's process.stdin never fires "readable" for TTYs ("data" works).
    # Two sites: startCapturingEarlyInput + agent-view attach.

    patch(
        "stdin readable→data (startCapturingEarlyInput)",
        (
            rb"(" + W + rb")=\(\)=>\{let (" + W + rb")=process\.stdin\.read\(\);"
            rb"while\(\2!==null\)\{if\(typeof \2===\"string\"\)(" + W + rb")\(\2\);"
            rb"\2=process\.stdin\.read\(\)\}\},"
            rb"process\.stdin\.on\(\"readable\",\1\)"
        ),
        lambda m: (
            m[1] + b"=()=>{}," +
            b'process.stdin.on("data",' + m[2] + b'=>{if(typeof ' + m[2]
            + b'==="string")' + m[3] + b"(" + m[2] + b")})"
        ),
    )

    # The agent-view early-input drainer loops process.stdin.read() inside its
    # readable handler. Deno never fires "readable" on a TTY, so add a parallel
    # "data" listener with the same Ctrl-C/push body; the original handler stays
    # for the direct drain call elsewhere (a no-op read loop under Deno).

    patch(
        "stdin readable→data (agent-view attach)",
        (
            rb"function (" + W + rb")\(\)\{let (" + W + rb");while\(\(\2=process\.stdin\.read\(\)\)!==null\)"
            rb'\{if\(\(typeof \2==="string"\?Buffer\.from\(\2,"utf8"\):\2\)\.includes\(3\)\)'
            rb'\{process\.emit\("SIGINT"\);return\}(' + W + rb")\.push\(\2\)\}\}"
            rb'process\.stdin\.on\("readable",\1\)'
        ),
        lambda m: (
            m[0]
            + b';process.stdin.on("data",' + m[2] + b'=>{if((typeof ' + m[2]
            + b'==="string"?Buffer.from(' + m[2] + b',"utf8"):' + m[2]
            + b').includes(3)){process.emit("SIGINT");return}' + m[3] + b".push(" + m[2] + b")})"
        ),
    )

    # --- Fix Deno-compile bridge spawn ---
    # Deno binaries eat --flags as V8 args; route through env(1) instead.

    patch(
        "deno bridge spawn fix",
        rb"let (" + W + rb")=(" + Q + rb")\((" + W + rb")\.execPath,(" + W + rb"),",
        lambda m: (
            b"let "
            + m[1]
            + b"="
            + m[2]
            + b'("env",["--",'
            + m[3]
            + b".execPath,..."
            + m[4]
            + b"],"
        ),
    )

    # --- Flip feature gates ---
    # Under DISABLE_TELEMETRY=1 GrowthBook never resolves, so defaults stick.

    Gate = tuple[bytes, str]

    core_gates: list[Gate] = [
        (b"tengu_ccr_bridge", "remote control"),
        (b"tengu_ccr_bundle_seed_enabled", "remote control bundle seed (async)"),
        (b"tengu_bridge_system_init", "bridge SDK init on connect"),
        (b"tengu_bridge_requires_action_details", "bridge rich tool-use payloads"),
        (b"tengu_remote_backend", "remote backend"),
        (b"tengu_immediate_model_command", "instant /model switching"),
        (b"tengu_fgts", "fine-grained tool streaming"),
        (b"tengu_surreal_dali", "scheduled agents/cron"),
    ]

    # /loop dynamic/persistent/prompt sub-modes; without them /loop falls back
    # to the bare cron path. push gates arm input-needed + generic pushes.
    loop_gates: list[Gate] = [
        (b"tengu_kairos_loop_dynamic", "/loop dynamic pacing"),
        (b"tengu_kairos_loop_persistent", "/loop persistent mode"),
        (b"tengu_kairos_loop_prompt", "/loop autonomous prompts"),
        (b"tengu_kairos_loop_keepalive", "/loop keepalive"),
        (b"tengu_kairos_push_notifications", "push notifications"),
        (b"tengu_kairos_input_needed_push", "push when input needed"),
    ]

    memory_gates: list[Gate] = [
        (b"tengu_herring_clock", "team memory directory"),
        (b"tengu_passport_quail", "typed combined memory prompts"),
        (b"tengu_paper_halyard", "memory dedup in nested dirs"),
    ]

    ux_gates: list[Gate] = [
        (b"tengu_kairos_brief", "brief output mode"),
        (b"tengu_destructive_command_warning", "destructive command warnings"),
        (b"tengu_amber_prism", "permission denial context"),
        (b"tengu_hawthorn_steeple", "context windowing"),
        (b"tengu_verified_vs_assumed", "verified-vs-assumed reporting"),
        (b"tengu_sparrow_ledger", "verify_prompt_arm (pairs with verified-vs-assumed)"),
        (b"tengu_orchid_mantis_v2", "default-NO /schedule offer (less noisy than v1)"),
        (b"tengu_silk_hinge", "message timestamps setting"),
        (b"tengu_terminal_sidebar", "status in terminal tab setting"),
        # Counterintuitive: ON suppresses the plan-upsell UI (gated by !T7()).
        (b"tengu_idle_amber_finch", "suppress plan-upsell prompts"),
    ]

    tool_gates: list[Gate] = [
        (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
        (b"tengu_plum_vx3", "web search reranking"),
        (b"tengu_harbor", "plugin marketplace"),
        (b"tengu_harbor_permissions", "plugin permissions"),
        (b"tengu_relay_chain_v1", "parallel command chaining guidance"),
        (b"tengu_edit_minimalanchor_jrn", "Edit tool minimal-anchor instructions"),
        (b"tengu_amber_sentinel", "Monitor tool for streaming bg scripts"),
        (b"tengu_mcp_subagent_prompt", "modern MCP subagent prompt (vs legacy)"),
        (b"tengu_mcp_skills", "MCP servers can advertise/serve Skills"),
        (b"tengu_malformed_tool_use_clean_retry", "clean retry on malformed tool calls"),
        (b"tengu_event_watchdog_default_on", "SSE stream-stall watchdog (recover hangs)"),
        (b"tengu_review_workflow_routing", "workflow-backed reviewer on high-effort review"),
    ]

    enable_gates(core_gates + loop_gates + memory_gates + ux_gates + tool_gates)

    # --- Disable the claude-api bundled skill ---
    # Its description is a ~200-token SDK/Bedrock matrix injected into every
    # system prompt — not relevant here.

    patch(
        "disable claude-api skill",
        rb'(' + W + rb')\(\{name:"claude-api",',
        lambda m: m[1] + b'({name:"claude-api",isEnabled:()=>!1,',
    )

    # --- grep/find shim: delegate to absolute Nix store paths ---
    # RYr(tool,bin,args) builds a bash function that re-execs the claude binary
    # with argv0=ugrep/bfs to reach the Bun ant-native search bundles; the Deno
    # repack drops those, so rewrite RYr to point at real tools by store path.
    # rg is unaffected (USE_BUILTIN_RIPGREP=0 sends Bash to system ripgrep).
    # Anchor on the 4-arg signature plus the `_cc_bin` marker unique to RYr, and
    # use brace-balanced parsing for the body end so internal restructures don't
    # drift the regex.

    def scan_js_block(blob: bytes, pos: int) -> int:
        """Return the offset just past the `}` closing the `{` at pos-1.
        Tracks ' " ` (with ''${...} interpolations) so braces inside strings
        don't count. Bun output has no comments or regex literals here."""
        depth: int = 1
        while pos < len(blob):
            c: bytes = blob[pos:pos + 1]
            if c == b"{":
                depth += 1
            elif c == b"}":
                depth -= 1
                if depth == 0:
                    return pos + 1
            elif c in (b"'", b'"'):
                pos += 1
                while pos < len(blob) and blob[pos:pos + 1] != c:
                    pos += 2 if blob[pos:pos + 1] == b"\\" else 1
            elif c == b"\x60":
                pos += 1
                while pos < len(blob) and blob[pos:pos + 1] != b"\x60":
                    if blob[pos:pos + 1] == b"\\":
                        pos += 2
                    elif blob[pos:pos + 2] == b"''${":
                        pos += 2
                        inner: int = 1
                        while pos < len(blob) and inner > 0:
                            ic: bytes = blob[pos:pos + 1]
                            if ic == b"{":
                                inner += 1
                            elif ic == b"}":
                                inner -= 1
                            pos += 1
                        continue
                    else:
                        pos += 1
            pos += 1
        sys.exit("grep/find shim: unbalanced braces")


    ryr_sig: bytes = (
        rb"function (" + W + rb")\((" + W + rb"),(" + W + rb"),(" + W + rb")=\[\],(" + W + rb")=\[\]\)\{"
    )
    ryr_match: re.Match[bytes] | None = None
    for cand in re.finditer(ryr_sig, data):
        if b"_cc_bin" in data[cand.end():cand.end() + 700]:
            ryr_match = cand
            break

    if ryr_match is None:
        log("grep/find shim: NOT FOUND")
    else:
        fn, tool, binv, args, cases = [ryr_match.group(i) for i in range(1, 6)]
        body_end: int = scan_js_block(data, ryr_match.end())
        ryr_new: bytes = (
            b"function " + fn + b"(" + tool + b"," + binv + b"," + args + b"=[]," + cases + b"=[]){"
            b"let L=" + args + b'.length>0?\x60''${' + args + b'.join(" ")} "$@"\x60:\'"$@"\';'
            b'let P=({ugrep:"${getExe' pkgs.ugrep "ugrep"}",'
            b'bfs:"${getExe pkgs.bfs}",'
            b'rg:"${getExe pkgs.ripgrep}"})[' + binv + b"]||" + binv + b";"
            b"return\x60function ''${" + tool + b"} { "
            b'if ! [ -x ''${P} ]; then command ''${' + tool + b'} "$@"; return; fi; '
            b"''${P} ''${L}; }\x60}"
        )
        data = data[:ryr_match.start()] + ryr_new + data[body_end:]
        log(f"grep/find shim: replaced {fn.decode()}")

    # --- Prepend Bun → Node shim (see bunShim above) ---

    bun_shim: bytes = b${toJSON bunShim}

    data = bun_shim + data
    log("Bun runtime polyfill: prepended")

    Path(sys.argv[1]).write_bytes(data)
  '';

  # Shut the clanka up
  shutUpClanka = pkgs.writeScriptBin "shut-up-clanka" /* py */ ''
    #!${getExe pkgs.python3}
    import json
    import re
    import sys

    SKIP_EXT = {"md", "markdown", "mdx", "rst", "txt", "adoc", "json"}

    WHITELIST = re.compile(
        r"^\s*(?:"
        r"(?:TODO|FIXME|NOTE|HACK|XXX|BUG|WARN|WARNING|SAFETY|PERF|SECURITY)\b"
        r"|\*|/\*\*|///|//!|#!|#\[|#region|#endregion|#\s*pragma|#\s*region"
        r"|.*\b(?:eslint|prettier|biome|ts-ignore|ts-expect|ts-nocheck|@ts-|noqa"
        r"|clippy::|pylint|mypy|rustfmt|gofmt|nolint|type:\s*ignore|coverage:)"
        r"|.*\b(?:SPDX|Copyright|License|https?://)"
        r")",
        re.IGNORECASE,
    )

    NARRATION = re.compile(
        r"^(?:update[ds]?|chang(?:e|ed|ing)|modif(?:y|ied)|remov(?:e|ed)|delet(?:e|ed)"
        r"|add(?:ed|ing)?|refactor(?:ed)?|renam(?:e|ed)|mov(?:e|ed)|replac(?:e|ed)"
        r"|fix(?:ed)?|introduc(?:e|ed)|now\s|new\s|using\s+the)\b",
        re.IGNORECASE,
    )

    RESTATE = re.compile(
        r"^(?:increment|decrement|set|get|return|call|creat(?:e|ing)|initiali[sz]e|init"
        r"|loop|iterate|check|assign|declar(?:e|ing)|defin(?:e|ing)|import|instantiate"
        r"|store|sav(?:e|ing)|load|print|log|handl(?:e|ing)|pars(?:e|ing)|convert"
        r"|build|mak(?:e|ing)|lock|unlock|open|clos(?:e|ing)|start|stop)\b",
        re.IGNORECASE,
    )

    ARTICLE = re.compile(r"^(?:the|this|a|an)\s+(?:following|above|below|next|previous)\b", re.IGNORECASE)
    DIVIDER = re.compile(r"^[-=*~#_]{3,}\s*$")
    ENDMARK = re.compile(r"^end\s+(?:of|function|class|method|if|loop|for|while|block)\b", re.IGNORECASE)
    WORD = re.compile(r"[A-Za-z]{3,}")


    def comment_body(line):
        s = line.strip()
        for lead in ("//", "#", "--"):
            if s.startswith(lead):
                return s[len(lead):].strip()
        return None


    def trailing_comment(line):
        m = re.search(r"\S\s+(//|#|--)\s?(.+)$", line)
        if not m:
            return None, None
        return m.group(2).strip(), line[: m.start(1)]


    def is_bad(body):
        return bool(
            NARRATION.match(body)
            or RESTATE.match(body)
            or ARTICLE.match(body)
            or DIVIDER.match(body)
            or ENDMARK.match(body)
        )


    def restates_code(body, code):
        cw = {w.lower() for w in WORD.findall(code)}
        bw = [w.lower() for w in WORD.findall(body)]
        return len(bw) <= 6 and any(w in cw for w in bw)


    def scan(text):
        hits = []
        for raw in text.splitlines():
            body = comment_body(raw)
            if body is not None:
                if WHITELIST.match(raw):
                    continue
                if is_bad(body):
                    hits.append(raw.strip())
                continue
            tbody, tcode = trailing_comment(raw)
            if tbody and not WHITELIST.match("// " + tbody):
                if is_bad(tbody) or restates_code(tbody, tcode):
                    hits.append(raw.strip())
        return hits


    def collect(tool, ti):
        if tool == "Write":
            return ti.get("content", ""), ti.get("file_path", "")
        if tool == "NotebookEdit":
            return ti.get("new_source", ""), ti.get("notebook_path", "")
        if tool == "MultiEdit":
            return "\n".join(e.get("new_string", "") for e in ti.get("edits", [])), ti.get("file_path", "")
        return ti.get("new_string", ""), ti.get("file_path", "")


    def main():
        try:
            data = json.load(sys.stdin)
        except Exception:
            return
        tool = data.get("tool_name", "")
        text, path = collect(tool, data.get("tool_input", {}))
        if not text:
            return
        ext = path.rsplit(".", 1)[-1].lower() if "." in path else ""
        if ext in SKIP_EXT:
            return
        hits = scan(text)
        if not hits:
            return
        shown = "\n".join(f"  - {h}" for h in hits[:8])
        extra = f"\n  ...and {len(hits) - 8} more" if len(hits) > 8 else ""
        msg = (
            f"⚠️ Comment check: {len(hits)} likely-redundant comment(s) in this edit:\n"
            f"{shown}{extra}\n"
            "Per CLAUDE.md, comments explain WHY not WHAT. Remove ones that restate the "
            "code or narrate the change; keep only a genuine why/footnote if warranted."
        )
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))


    if __name__ == "__main__":
        main()
  '';

  # Deno-compiled so we can stub the Clearcut telemetry watchdog.
  chrome-devtools-mcp =
    let
      version = "1.0.1";
    in
    pkgs.writeShellScriptBin "chrome-devtools-mcp" /* sh */ ''
      set -euo pipefail
      export PATH="${pkgs.deno}/bin:$PATH"

      CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/chrome-devtools-mcp"
      BIN="$CACHE/chrome-devtools-mcp-${version}"

      if [ ! -x "$BIN" ]; then
        mkdir -p "$CACHE"
        DENO_DIR="$CACHE/.deno"
        export DENO_DIR
        deno cache "npm:chrome-devtools-mcp@${version}"
        cat > "$DENO_DIR/npm/registry.npmjs.org/chrome-devtools-mcp/${version}/build/src/telemetry/WatchdogClient.js" <<'STUB'
      export class WatchdogClient { constructor() {} send() {} }
      STUB
        deno compile --allow-all --output "$BIN" "npm:chrome-devtools-mcp@${version}" 2>&1
        rm -rf "$DENO_DIR"
      fi

      exec "$BIN" --no-usage-statistics "$@"
    '';

  # Pinned to mlamp's fork @ rtk-ai/rtk#1339 (CLAUDE_CONFIG_DIR support); the
  # PR is develop-based and doesn't cleanly fetchpatch onto v0.37.2. Drop the
  # fork once it lands upstream.
  rtk = pkgs.rustPlatform.buildRustPackage {
    pname = "rtk";
    version = "0.37.2";

    src = pkgs.fetchFromGitHub {
      owner = "mlamp";
      repo = "rtk";
      rev = "985f22e37519153f86582a08e6f6dd36152f8f79";
      hash = "sha256-4jRKsWSY30cjNQHmP7iVOBuNLe1ZWEuJO8FvCIBlv20=";
    };

    cargoHash = "sha256-MXWqVIRV+nhlbyDTigGdvY3QJ30XnxV6/Q4Y/7CbHaQ=";

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
      USE_BUILTIN_RIPGREP = "0";
      UV_THREADPOOL_SIZE = "16";
    };

    attribution.commit = "";
    attribution.pr = "";

    permissions.allow = [
      "Read"
      "mcp__chrome-devtools__*"
      "mcp__ida-pro-mcp__*"
    ];
    permissions.defaultMode = "bypassPermissions";

    hooks.PreToolUse = singleton {
      matcher = "Bash";
      hooks = singleton {
        type = "command";
        command = "/home/amaanq/.claude/hooks/rtk-rewrite.sh";
      };
    };
    hooks.PostToolUse = singleton {
      matcher = "Edit|Write|MultiEdit|NotebookEdit";
      hooks = singleton {
        type = "command";
        command = getExe shutUpClanka;
      };
    };
    hooks.WorktreeCreate = singleton {
      hooks = singleton {
        type = "command";
        command = /* bash */ ''jj workspace add "$(cat /dev/stdin | jq -r '.name')"'';
      };
    };
    hooks.WorktreeRemove = singleton {
      hooks = singleton {
        type = "command";
        command = /* bash */ ''jj workspace forget "$(cat /dev/stdin | jq -r '.worktree_path')"'';
      };
    };

    extraKnownMarketplaces.openai-codex.source = {
      source = "github";
      repo = "openai/codex-plugin-cc";
    };

    enabledPlugins = {
      "clangd-lsp@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "code-simplifier@claude-plugins-official" = true;
      "codex@openai-codex" = true;
      "kotlin-lsp@claude-plugins-official" = true;
      "ralph-loop@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "superpowers@claude-plugins-official" = true;
    };

    statusLine = {
      type = "command";
      command = getExe statusLine;
    };

    skipWebFetchPreflight = true;

    spinnerVerbs.mode = "replace";
    spinnerVerbs.verbs = [
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

    cleanupPeriodDays = 90;
    alwaysThinkingEnabled = true;
    remoteControlAtStartup = true;
    showClearContextOnPlanAccept = true;
    skipDangerousModePermissionPrompt = true;
  };

  settingsJson = pkgs.writeText "claude-settings.json" (toJSON settings);

  claude = mkSlopLauncher {
    name = "claude";
    cacheSubdir = "claude-code";
    versionUrl = "https://registry.npmjs.org/@anthropic-ai/claude-code/latest";
    versionParser = "get version";
    runtimeDeps = [
      pkgs.procps
      pkgs.ripgrep
    ]
    ++ optionals config.isLinux [
      pkgs.bubblewrap
      pkgs.socat
    ];
    preExec = /* nu */ ''
      let config_dir = $env | get --optional "CLAUDE_CONFIG_DIR" | default (
        $env
          | get --optional "XDG_CONFIG_HOME"
          | default ($env.HOME | path join ".config")
          | path join "claude"
      )
      mkdir $config_dir

      # Slop refuses a read-only settings.json, so copy it.
      cp --force ${settingsJson} ($config_dir | path join "settings.json")

      r#'${toJSON settings.env}'# | from json | load-env
    '';
    fetch = /* nu */ ''
      let arch = match ($nu.os-info.arch | str downcase) {
        "x86_64" | "x64" | "amd64" => "x64"
        "aarch64" | "arm64" => "arm64"
        $arch => { error make { msg: $"unsupported arch: ($arch)" } }
      }

      let platform = match ($nu.os-info.name | str downcase) {
        "linux" => $"linux-($arch)"
        "macos" | "darwin" => $"darwin-($arch)"
        $os => { error make { msg: $"unsupported os: ($os)" } }
      }

      let pkg = $"@anthropic-ai/claude-code-($platform)"
      let tarball_url = $"https://registry.npmjs.org/($pkg)/-/claude-code-($platform)-($version).tgz"

      let tgz_dir = $cache | path join "tgz"
      mkdir $tgz_dir
      let tgz = $tgz_dir | path join $"claude-code-($platform)-($version).tgz"

      # atomic rename so a partial download isn't cached as good.
      if not ($tgz | path exists) {
        let tmp = $"($tgz).tmp"
        print --stderr $"(ansi cyan)fetch:(ansi reset) ($tarball_url)"
        http get --raw $tarball_url | save --force --raw $tmp
        mv $tmp $tgz
      }

      let workdir = $cache | path join $"build-($version)"
      rm -rf $workdir
      mkdir $workdir

      ^${getExe pkgs.gnutar} -xzf $tgz -C $workdir
      let native_bin = $workdir | path join "package" "claude"
      if not ($native_bin | path exists) {
        error make { msg: $"lift: ($native_bin) missing after tar extract" }
      }

      let cli = $workdir | path join "cli.cjs"
      ^${getExe lift} $native_bin $cli
      ^${getExe patch} $cli

      # Bun keeps http/ws/schema libs as runtime-external; Deno has no
      # equivalent, so resolve into node_modules/ and --include the tree.
      r#'${
        toJSON {
          name = "claude-code-lifted";
          type = "commonjs";
          dependencies = {
            ws = "^8";
            undici = "^6";
            node-fetch = "^3";
            ajv = "^8";
            ajv-formats = "^3";
            yaml = "^2";
            # Bun shim deps; pinned to CJS-compatible majors.
            string-width = "^4";
            strip-ansi = "^6";
            wrap-ansi = "^7";
            semver = "^7";
            # PTY backing Bun.Terminal for `claude --bg-pty-host` (agent view).
            "@homebridge/node-pty-prebuilt-multiarch" = "^0.13.0";
          };
        }
      }'# | save --force ($workdir | path join "package.json")

      cd $workdir
      $env.DENO_DIR = ($workdir | path join ".deno")
      ^${getExe pkgs.deno} install --node-modules-dir=auto
      ^${getExe pkgs.deno} compile --allow-all --no-check --node-modules-dir=auto --include=node_modules --output $binary_path "cli.cjs"

      cd $cache  # nushell can't rm the directory it's inside
      rm -rf $workdir
    '';
  };
in
{
  options.programs.claude-code.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    internal = true;
    default = claude;
  };

  config = {
    environment.systemPackages = [
      chrome-devtools-mcp
      rtk
      claude
    ];

    environment.variables.CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
  };
}
