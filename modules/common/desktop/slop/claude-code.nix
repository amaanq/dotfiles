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


    def flip_gates(gates: list[tuple[bytes, str]]) -> None:
        """Flip all gate defaults from false to true in a single regex pass."""
        global data
        gate_keys: list[bytes] = [g for g, _ in gates]
        labels: dict[bytes, str] = dict(gates)
        alternation: bytes = b"|".join(re.escape(g) for g in gate_keys)
        pat: bytes = W + rb'\("(' + alternation + rb')",!1\)'
        flipped: set[bytes] = set()

        def replacer(m: re.Match[bytes]) -> bytes:
            flipped.add(m.group(1))
            return m[0].replace(b",!1)", b",!0)")

        data, n = re.subn(pat, replacer, data)
        log(f"feature gates: {n} flipped across {len(flipped)} gates")
        for key in gate_keys:
            status = "ok" if key in flipped else "MISSED"
            log(f"  {labels[key]} [{status}]")


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
        (b'name:"bridge-kick",description:"Inject bridge failure states', "/bridge-kick"),
        (b'name:"files",description:"List all files currently in context"', "/files"),
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

    # --- Bypass telemetry gate in feature flag checker ---
    # Drops the trailing `||telemetryDisabled()` so gates still resolve under
    # DISABLE_TELEMETRY=1 while preserving the bedrock/vertex/foundry branch.

    patch(
        "telemetry gate (drop telemetry-disabled check)",
        (
            rb"function (" + W + rb")\(\)\{return (" + W + rb")\(process\.env\.CLAUDE_CODE_USE_BEDROCK\)"
            rb"\|\|\2\(process\.env\.CLAUDE_CODE_USE_VERTEX\)"
            rb"\|\|\2\(process\.env\.CLAUDE_CODE_USE_FOUNDRY\)"
            rb"\|\|" + W + rb"\(\)\}"
        ),
        lambda m: re.sub(rb"\|\|" + W + rb"\(\)\}$", b"||!1}", m[0]),
    )

    # --- Force Av() async-gate to always resolve true ---
    # Av() is the async feature-gate resolver; every call-site we hit
    # (tengu_ccr_bridge, ccr_bundle_seed, harbor, …) is one we want enabled,
    # and the default-false path bypasses the gate even after Cq6 is patched.
    # Av() never writes telemetry, so a blanket !0 is safe.

    patch(
        "Av() force-true for telemetry-off builds",
        # Negative lookahead bounds the body match — the inner resolver name
        # (Irq → aeq → ...) rotates, so capture rather than pin.
        rb"async function (" + W + rb")\(H\)\{(?:(?!async function ).){60,400}?return " + W + rb"\(H,!1,!0\)\}",
        lambda m: b"async function " + m[1] + b"(H){return !0}",
    )

    # --- Restore 1h prompt cache TTL when telemetry is off ---
    # https://github.com/anthropics/claude-code/issues/45381
    # Widen the GrowthBook allowlist default to ["*"] so batch agents and
    # less-common query sources also get 1h cache_control.

    patch(
        "1h prompt cache TTL fallback",
        rb'(' + W + rb')\("tengu_prompt_cache_1h_config",\{allowlist:\[[^\]]+\]\}\)\.allowlist\?\?\[\]',
        lambda m: m[1] + b'("tengu_prompt_cache_1h_config",{allowlist:["*"]}).allowlist??[]',
    )

    # --- Disable tengu_keybindings_dom (new chord dispatcher) ---
    # The 2.1.118 DOM-style focus manager wedges the TUI during /rewind: the
    # message selector remount drops the focus target, stdin pauses, fd 0
    # leaves epoll, Ctrl-C has no reader. Flipping reverts to the 117 path.

    patch(
        "disable new keybindings dispatcher (causes /rewind hang in 2.1.118)",
        rb'(' + W + rb')\("tengu_keybindings_dom",!0\)',
        lambda m: m[1] + b'("tengu_keybindings_dom",!1)',
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

    patch(
        "stdin readable→data (agent-view attach)",
        (
            rb'if\(q\.on\("readable",d\),"resume"in q&&"pause"in q\)'
            rb'q\.resume\(\),q\.pause\(\)'
        ),
        # d() loops q.read() and calls g(chunk); g is in enclosing scope.
        lambda m: b'q.on("data",g)',
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
        (b"tengu_bridge_system_init", "bridge SDK init on connect"),
        (b"tengu_bridge_client_presence_enabled", "bridge presence heartbeats"),
        (b"tengu_bridge_requires_action_details", "bridge rich tool-use payloads"),
        (b"tengu_remote_backend", "remote backend"),
        (b"tengu_immediate_model_command", "instant /model switching"),
        (b"tengu_fgts", "fine-grained tool streaming"),
        (b"tengu_streaming_tool_execution2", "streaming tool execution v2"),
        (b"tengu_auto_background_agents", "background agent timeout"),
        (b"tengu_plan_mode_interview_phase", "plan mode interview"),
        (b"tengu_surreal_dali", "scheduled agents/cron"),
    ]

    # Agent view (`claude agents` TUI, `--bg`, /background) — slate_meadow is
    # the fleet gate, fg_left_arrow_agents adds the left-arrow shortcut.
    agent_view_gates: list[Gate] = [
        (b"tengu_slate_meadow", "agent view fleet gate (--bg, claude agents TUI)"),
        (b"tengu_fg_left_arrow_agents", "left-arrow shortcut into agents fleet"),
    ]

    # /loop dynamic/persistent/prompt sub-modes; without them /loop falls back
    # to the bare cron path. push gates arm input-needed + generic pushes.
    loop_gates: list[Gate] = [
        (b"tengu_kairos_loop_dynamic", "/loop dynamic pacing"),
        (b"tengu_kairos_loop_persistent", "/loop persistent mode"),
        (b"tengu_kairos_loop_prompt", "/loop autonomous prompts"),
        (b"tengu_kairos_push_notifications", "push notifications"),
        (b"tengu_kairos_input_needed_push", "push when input needed"),
    ]

    memory_gates: list[Gate] = [
        (b"tengu_pebble_leaf_prune", "message pruning"),
        (b"tengu_herring_clock", "team memory directory"),
        (b"tengu_passport_quail", "typed combined memory prompts"),
        (b"tengu_paper_halyard", "memory dedup in nested dirs"),
    ]

    ux_gates: list[Gate] = [
        (b"tengu_coral_fern", "grep hints in prompt"),
        (b"tengu_kairos_brief", "brief output mode"),
        (b"tengu_destructive_command_warning", "destructive command warnings"),
        (b"tengu_amber_prism", "permission denial context"),
        (b"tengu_hawthorn_steeple", "context windowing"),
        (b"tengu_loud_sugary_rock", "Opus 4.7 terse output guidance"),
        (b"tengu_loud_sugary_rock2", "Opus 4.7 terse output guidance v2"),
        (b"tengu_verified_vs_assumed", "verified-vs-assumed reporting"),
        (b"tengu_sparrow_ledger", "verify_prompt_arm (pairs with verified-vs-assumed)"),
        (b"tengu_orchid_mantis_v2", "default-NO /schedule offer (less noisy than v1)"),
        (b"tengu_silk_hinge", "message timestamps setting"),
        (b"tengu_terminal_sidebar", "status in terminal tab setting"),
        (b"tengu_birch_compass", "/usage 'What's contributing' breakdown block"),
    ]

    tool_gates: list[Gate] = [
        (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
        (b"tengu_plum_vx3", "web search reranking"),
        (b"tengu_cork_m4q", "batch command processing"),
        (b"tengu_harbor", "plugin marketplace"),
        (b"tengu_harbor_permissions", "plugin permissions"),
        (b"tengu_relay_chain_v1", "parallel command chaining guidance"),
        (b"tengu_edit_minimalanchor_jrn", "Edit tool minimal-anchor instructions"),
        (b"tengu_slate_reef", "Read tool clearer offset/limit docs"),
        (b"tengu_otk_slot_v1", "output-token escalation for complex tasks"),
        (b"tengu_onyx_basin_m1k", "subagent tool-result truncation"),
        (b"tengu_sub_nomdrep_q7k", "block subagent report .md writes"),
        (b"tengu_amber_sentinel", "Monitor tool for streaming bg scripts"),
        (b"tengu_miraculo_the_bard", "skip penguin-mode startup prefetch"),
        (b"tengu_noreread_q7m_velvet", "sharper 'wasted read' feedback"),
        (b"tengu_mcp_subagent_prompt", "modern MCP subagent prompt (vs legacy)"),
    ]

    flip_gates(core_gates + agent_view_gates + loop_gates + memory_gates + ux_gates + tool_gates)

    patch(
        "background agent timeout",
        rb'"tengu_auto_background_agents",![01]\)\)return 120000',
        lambda m: m[0].replace(b"120000", b"240000"),
    )

    # --- Disable the claude-api bundled skill ---
    # Its description is a ~200-token SDK/Bedrock matrix injected into every
    # system prompt — not relevant here.

    patch(
        "disable claude-api skill",
        rb'(' + W + rb')\(\{name:"claude-api",description:',
        lambda m: m[1] + b'({name:"claude-api",isEnabled:()=>!1,description:',
    )

    # --- Replace usage fetch with self-contained OAuth implementation ---
    # Stock falls back to x-api-key when telemetry is off, but /api/oauth/usage
    # needs Bearer + oauth beta header. Read credentials directly.

    usage_fn_pat: bytes = (
        rb"async function (" + W + rb")\(\)\{"
        rb"(?:if\(!" + W + rb"\(\)\|\|!" + W + rb"\(\)\)return\{\};)?"
        rb"let " + W + rb"=" + W + rb"\(\);if\(" + W + rb"&&" + W + rb"\(" + W + rb"\." + W + rb"\)\)return null;"
        rb"let " + W + rb"=" + W + rb"\(\);if\(" + W + rb"\.error\)throw Error\(\x60Auth error: \x24\{" + W + rb"\.error\}\x60\);"
        rb"let " + W + rb"=\{[^}]+\}," + W + rb"=\x60\x24\{(" + W + rb")\(\)\.(" + W + rb")\}/api/oauth/usage\x60;"
        rb"return\(await (" + W + rb")\.get\(" + W + rb",\{headers:" + W + rb",timeout:5000\}\)\)\.data\}"
    )

    usage_fn_match: re.Match[bytes] | None = re.search(usage_fn_pat, data)
    if usage_fn_match:
        fn_name: bytes = usage_fn_match.group(1)
        config_fn: bytes = usage_fn_match.group(2)
        base_url_key: bytes = usage_fn_match.group(3)
        http_client: bytes = usage_fn_match.group(4)
        replacement: bytes = (
            b"async function " + fn_name + b"(){"
            b"const _cd=(process.env.CLAUDE_CONFIG_DIR||"
            b'(Deno.env.get("HOME")+"/.config/claude"));'
            b"let _tk;"
            b'try{const _cr=JSON.parse(new TextDecoder().decode('
            b'Deno.readFileSync(_cd+"/.credentials.json")));'
            b"_tk=_cr?.claudeAiOauth?.accessToken}catch{return{}}"
            b"if(!_tk)return{};"
            b'const _cp="/tmp/.claude-usage-"+_tk.slice(-8)+".json";'
            b"try{const _s=Deno.statSync(_cp);"
            b"if(Date.now()-_s.mtime.getTime()<60000)"
            b'return JSON.parse(new TextDecoder().decode(Deno.readFileSync(_cp)))}catch{}'
            b"const _h={" + b'"Content-Type":"application/json",'
            b'"Authorization":"Bearer "+_tk,'
            b'"anthropic-beta":"oauth-2025-04-20"};'
            b"const _u=`''${" + config_fn + b"()." + base_url_key + b"}/api/oauth/usage`;"
            b"const _r=(await " + http_client + b".get(_u,{headers:_h,timeout:5000})).data;"
            b'try{Deno.writeTextFileSync(_cp,JSON.stringify(_r))}catch{}'
            b"return _r}"
        )
        data = data.replace(usage_fn_match[0], replacement)
        log("usage fetch: replaced")
    else:
        log("usage fetch: pattern NOT FOUND")

    # --- grep/find/rg shim: delegate to absolute Nix store paths ---
    # Stock re-execs argv[0]=ugrep/bfs/rg expecting Bun ant-native bundles;
    # the Deno repack drops those, so point at real tools by store path.
    # Anchor on (H,_,q=[]) (with optional 2.1.139 K=[] fourth param) plus the
    # `\x60function ''${H} {` bash header it must emit; two other functions
    # share the signature so the header disambiguates. Use brace-balanced
    # parsing for the body end so internal restructures don't drift the regex.

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
        sys.exit("a38 shim: unbalanced braces")


    a38_sig: bytes = rb"function (" + W + rb")\(H,_,q=\[\](?:,K=\[\])?\)\{"
    a38_match: re.Match[bytes] | None = None
    for cand in re.finditer(a38_sig, data):
        if b"\x60function ''${H} {" in data[cand.end():cand.end() + 800]:
            a38_match = cand
            break

    if a38_match is None:
        log("grep/find/rg shim: NOT FOUND")
    else:
        fn_name: bytes = a38_match.group(1)
        body_end: int = scan_js_block(data, a38_match.end())
        a38_new: bytes = (
            b"function " + fn_name + b"(H,_,q=[]){"
            b'let L=q.length>0?\x60''${q.join(" ")} "$@"\x60:\'"$@"\';'
            b'let P=({ugrep:"${getExe' pkgs.ugrep "ugrep"}",'
            b'bfs:"${getExe pkgs.bfs}",'
            b'rg:"${getExe pkgs.ripgrep}"})[_]||_;'
            b"return\x60function ''${H} { "
            b'if ! [ -x ''${P} ]; then command ''${H} "$@"; return; fi; '
            b"''${P} ''${L}; }\x60}"
        )
        data = data[:a38_match.start()] + a38_new + data[body_end:]
        log(f"grep/find/rg shim: replaced {fn_name.decode()}")

    # --- Prepend Bun → Node shim (see bunShim above) ---

    bun_shim: bytes = b${toJSON bunShim}

    data = bun_shim + data
    log("Bun runtime polyfill: prepended")

    Path(sys.argv[1]).write_bytes(data)
  '';

  # Deno-compiled so we can stub the Clearcut telemetry watchdog.
  chrome-devtools-mcp =
    let
      version = "1.0.1";
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
