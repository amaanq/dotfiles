from __future__ import annotations

import re
import sys
from collections.abc import Callable
from pathlib import Path
from typing import Union

type Replacement = Union[bytes, Callable[[re.Match[bytes]], bytes]]

W: bytes = rb"[\w$]+"
data: bytes = Path(sys.argv[1]).read_bytes()

SEARCH_WINDOW: int = 500


def log(msg: str) -> None:
   sys.stderr.write(msg + "\n")


def patch(label: str, pattern: bytes, replacement: Replacement) -> None:
   global data
   data, n = re.subn(pattern, replacement, data)
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


# --- AGENTS.md support: claude can now load AGENTS.md alongside CLAUDE.md for project configs ---

agents_pat: bytes = (
   rb"let (" + W + rb")=(" + W + rb")\((" + W + rb'),"CLAUDE\.md"\);'
   rb"(" + W + rb")\.push\(\.\.\.(" + W + rb')\(\1,"Project",([^)]+)\)\)'
)


def agents_repl(m: re.Match[bytes]) -> bytes:
   var, path_join, dir_, arr, load_fn, tail = [m.group(i) for i in range(1, 7)]
   return (
      b'for(let _f of["CLAUDE.md","AGENTS.md"]){let '
      + var
      + b"="
      + path_join
      + b"("
      + dir_
      + b",_f);"
      + arr
      + b".push(..."
      + load_fn
      + b"("
      + var
      + b',"Project",'
      + tail
      + b"))}"
   )


patch("agents.md loader", agents_pat, agents_repl)

# --- macOS config path: use /etc/claude-code instead of ~/Library/Application Support because the latter is retarded for cli tools ---

data = data.replace(
   b'case"macos":return"/Library/Application Support/ClaudeCode"',
   b'case"macos":return"/etc/claude-code"',
)

# --- Enable hard-disabled slash commands: /btw, /files, /tag ---

slash_commands: list[tuple[bytes, str]] = [
   (b'name:"btw",description:"Ask a quick side question', "/btw"),
   (b'name:"files",description:"List all files currently in context"', "/files"),
   (b'name:"tag",userFacingName', "/tag"),
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

# --- Bypass thinkback gate (no default arg, different replacement strategy) ---

patch("thinkback gate", W + rb'\("tengu_thinkback"\)', b'!0||"tengu_thinkback"')

# --- Bypass telemetry gate in feature flag checker ---
# _n6 has `if(!pi())return!1` before checking cachedGrowthBookFeatures.
# With telemetry off, pi() returns false and cached flags are never read.
# Remove that early return so the cache is always consulted.

patch(
   "feature flag telemetry gate",
   rb"if\(!" + W + rb"\(\)\)return!1;if\(" + W + rb"\(\)\." + W + rb"\?\.\[",
   lambda m: m[0].replace(b"return!1;", b"", 1),
)

# --- Fix Deno-compile bridge spawn ---
# Deno-compiled binaries eat --flags as V8 args, so we route spawns through
# env(1) to pass them as normal CLI flags instead.

patch(
   "deno bridge spawn fix",
   rb"let (" + W + rb")=(" + W + rb")\((" + W + rb")\.execPath,(" + W + rb"),",
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
# DISABLE_TELEMETRY=1 prevents GrowthBook feature flag resolution, so all gates
# fall back to their hardcoded defaults (false). Flip them to true.

Gate = tuple[bytes, str]

core_gates: list[Gate] = [
   (b"tengu_cobalt_compass", "1M context window"),
   (b"tengu_ccr_bridge", "remote control"),
   (b"tengu_remote_backend", "remote backend"),
   (b"tengu_keybinding_customization_release", "custom keybindings"),
   (b"tengu_streaming_text", "token-by-token streaming"),
   (b"tengu_immediate_model_command", "instant /model switching"),
   (b"tengu_fgts", "fine-grained tool streaming"),
]

memory_gates: list[Gate] = [
   (b"tengu_session_memory", "session memory"),
   (b"tengu_sm_compact", "memory survives compaction"),
   (b"tengu_compact_cache_prefix", "cache-aware compaction"),
   (b"tengu_compact_streaming_retry", "compact stream retry"),
   (b"tengu_pebble_leaf_prune", "message pruning"),
]

ux_gates: list[Gate] = [
   (b"tengu_coral_fern", "grep hints in prompt"),
   (b"tengu_sotto_voce", "output efficiency"),
   (b"tengu_kairos_brief", "brief output mode"),
   (b"tengu_bergotte_lantern", "concise polished output"),
   (b"tengu_permission_explainer", "permission explanations"),
   (b"tengu_destructive_command_warning", "destructive command warnings"),
   (b"tengu_pr_status_cli", "PR status footer"),
   (b"tengu_copper_wren", "edit feedback messages"),
   (b"tengu_quiet_hollow", "thinking summaries"),
   (b"tengu_lean_cast", "lean system prompt"),
   (b"tengu_amber_prism", "permission denial context"),
]

tool_gates: list[Gate] = [
   (b"tengu_mcp_elicitation", "MCP tool prompting"),
   (b"tengu_tool_input_aliasing", "param alias resolution"),
   (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
   (b"tengu_copper_bridge", "chrome bridge context"),
   (b"tengu_system_prompt_global_cache", "global system prompt cache"),
   (b"tengu_tst_hint_m7r", "tool search hints"),
   (b"tengu_glacier_2xr", "deferred tool improvements"),
   (b"tengu_basalt_3kr", "MCP instruction delta"),
   (b"tengu_cobalt_frost", "voice conversation engine"),
   (b"tengu_scarf_coffee", "API context management"),
   (b"tengu_quartz_lantern", "remote tool use diff"),
   (b"tengu_marble_anvil", "thinking edits"),
   (b"tengu_marble_whisper2", "inline annotations"),
   (b"tengu_orchid_trellis", "plugin marketplace"),
   (b"tengu_pewter_gull", "PDF line limiting"),
   (b"tengu_moth_copse", "relevant memory recall"),
   (b"tengu_cork_m4q", "batch command processing"),
]

flip_gates(core_gates + memory_gates + ux_gates + tool_gates)

# --- Kill claude-developer-platform bundled skill (this uses ~400 tokens per turn, it's dead weight) ---

data = data.replace(
   b'name:"claude-developer-platform",description:`',
   b'name:"claude-developer-platform",isEnabled:()=>!1,description:`',
)
log("killed claude-developer-platform skill")

# --- Enrich context_window status line data ---

ctx_pat: bytes = (
   rb"context_window:\{total_input_tokens:(" + W + rb"\(\)),"
   rb"total_output_tokens:(" + W + rb"\(\)),"
   rb"context_window_size:(" + W + rb"),"
   rb"current_usage:(" + W + rb"),"
   rb"used_percentage:(" + W + rb")\.used,"
   rb"remaining_percentage:\5\.remaining\}"
)
rl_pat: bytes = (
   rb"("
   + W
   + rb')=\{status:"allowed",unifiedRateLimitFallbackAvailable:!1,isUsingOverage:!1\}'
)

rl_match: re.Match[bytes] | None = re.search(rl_pat, data)
ctx_match: re.Match[bytes] | None = re.search(ctx_pat, data)

if ctx_match and rl_match:
   inp_tok, out_tok, win_size, usage, pct = [ctx_match.group(i) for i in range(1, 6)]
   rate_limit: bytes = rl_match.group(1)
   data = data.replace(
      ctx_match[0],
      b"context_window:{...(" + usage + b"||{}),"
      b"context_window_size:" + win_size + b",current_usage:" + usage + b","
      b"used_percentage:" + pct + b".used,remaining_percentage:" + pct + b".remaining,"
      b"rate_limit:" + rate_limit + b",s_in:" + inp_tok + b",s_out:" + out_tok + b"}",
   )
   log("context window statusline: patched")
else:
   log(
      f"context window statusline: NOT FOUND (ctx={'yes' if ctx_match else 'no'}, rl={'yes' if rl_match else 'no'})"
   )

# --- Cache oauth/usage to disk ---
# Both /usage and the statusline need usage data but the API rate-limits hard.
# We wrap the fetch function with a 60s file cache at /tmp/.claude-usage.json so
# only one actual request goes out; everyone else reads the cache.

usage_anchor: bytes = b"api/oauth/usage"
usage_pos: int = data.find(usage_anchor)
if usage_pos >= 0:
   # Find the enclosing "async function NAME(){" by scanning backwards
   fn_start: int = data.rfind(b"async function ", max(0, usage_pos - 500), usage_pos)
   if fn_start >= 0:
      # Find the function's closing brace by counting braces forward
      brace_depth: int = 0
      fn_end: int = fn_start
      for i in range(fn_start, min(len(data), usage_pos + 500)):
         if data[i : i + 1] == b"{":
            brace_depth += 1
         elif data[i : i + 1] == b"}":
            brace_depth -= 1
            if brace_depth == 0:
               fn_end = i + 1
               break

      original_fn: bytes = data[fn_start:fn_end]
      # Extract function name from "async function NAME(){"
      fn_name_match = re.match(rb"async function (" + W + rb")\(\)\{", original_fn)
      if fn_name_match:
         fn_name: bytes = fn_name_match.group(1)
         # Rename original to _uc_ORIG, create caching wrapper with the original name
         renamed: bytes = b"_uc_" + fn_name
         patched_fn: bytes = (
            b"async function "
            + renamed
            + original_fn[len(b"async function " + fn_name) :]
            + b"async function "
            + fn_name
            + b'(){const _fs=require("fs"),'
            b'_cp="/tmp/.claude-usage.json";'
            b"try{const _s=_fs.statSync(_cp);"
            b"if(Date.now()-_s.mtimeMs<60000)"
            b'return JSON.parse(_fs.readFileSync(_cp,"utf8"))'
            b"}catch{}"
            b"const _r=await " + renamed + b"();"
            b"try{_fs.writeFileSync(_cp,JSON.stringify(_r))}catch{}"
            b"return _r}"
         )
         data = data[:fn_start] + patched_fn + data[fn_end:]
         log("usage cache: patched")
      else:
         log("usage cache: fn name not matched")
   else:
      log("usage cache: enclosing function not found")
else:
   log("usage cache: NOT FOUND")

Path(sys.argv[1]).write_bytes(data)
