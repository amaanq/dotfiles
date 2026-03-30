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


# --- AGENTS.md support ---
# The CLAUDE.md loader only reads CLAUDE.md. Patch it to also load AGENTS.md
# from the same directories. Pattern: let VAR=ME(DIR,"CLAUDE.md");ARR.push(...await XE(VAR,"Project",ARG,BOOL))

agents_pat: bytes = (
   rb"let (" + W + rb")=(" + W + rb")\((" + W + rb'),"CLAUDE\.md"\);'
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
# The chain is: h8(featureGate) bails to default if !Qo(); Qo()=Ew6();
# Ew6()=!Cq6(); Cq6() returns true when on bedrock/vertex/foundry OR when
# user-facing telemetry is disabled (s_1()/equivalent). Drop the trailing
# telemetry-disabled check so feature gates still resolve with
# DISABLE_TELEMETRY=1 while preserving the bedrock/vertex/foundry detection.
# Anchor on the stable env-var literal CLAUDE_CODE_USE_BEDROCK; the obfuscated
# function name (Cq6) and the trailing wrapper name (s_1) both rotate.

patch(
   "telemetry gate (drop telemetry-disabled check)",
   (
      rb"function (" + W + rb")\(\)\{return F6\(process\.env\.CLAUDE_CODE_USE_BEDROCK\)"
      rb"\|\|F6\(process\.env\.CLAUDE_CODE_USE_VERTEX\)"
      rb"\|\|F6\(process\.env\.CLAUDE_CODE_USE_FOUNDRY\)"
      rb"\|\|" + W + rb"\(\)\}"
   ),
   lambda m: re.sub(rb"\|\|" + W + rb"\(\)\}$", b"||!1}", m[0]),
)

# --- Restore 1h prompt cache TTL when telemetry is off ---
# https://github.com/anthropics/claude-code/issues/45381
# maY() gates the "ttl":"1h" cache_control on a GrowthBook allowlist
# (tengu_prompt_cache_1h_config). With telemetry off the lookup falls
# through to the {} default, so .allowlist is undefined and the ??[]
# fallback produces an empty array — every querySource fails the .some()
# match and falls back to 5min TTL. Replace the empty fallback with ["*"]
# so any defined querySource matches.

patch(
   "1h prompt cache TTL fallback",
   rb'h8\("tengu_prompt_cache_1h_config",\{\}\)\.allowlist\?\?\[\]',
   b'h8("tengu_prompt_cache_1h_config",{}).allowlist??["*"]',
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
   (b"tengu_ccr_bridge", "remote control"),
   (b"tengu_bridge_system_init", "bridge SDK init on connect"),
   (b"tengu_remote_backend", "remote backend"),
   (b"tengu_immediate_model_command", "instant /model switching"),
   (b"tengu_fgts", "fine-grained tool streaming"),
   (b"tengu_auto_background_agents", "background agent timeout"),
   (b"tengu_plan_mode_interview_phase", "plan mode interview"),
   (b"tengu_surreal_dali", "scheduled agents/cron"),
]

memory_gates: list[Gate] = [
   # (b"tengu_session_memory", "session memory"),  # auto-memory; pollutes unrelated convos
   (b"tengu_pebble_leaf_prune", "message pruning"),
   (b"tengu_herring_clock", "team memory directory"),
   (b"tengu_passport_quail", "typed combined memory prompts"),
]

ux_gates: list[Gate] = [
   (b"tengu_coral_fern", "grep hints in prompt"),
   (b"tengu_kairos_brief", "brief output mode"),
   (b"tengu_destructive_command_warning", "destructive command warnings"),
   (b"tengu_amber_prism", "permission denial context"),
   (b"tengu_hawthorn_steeple", "context windowing"),
]

tool_gates: list[Gate] = [
   (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
   (b"tengu_glacier_2xr", "deferred tool improvements"),
   (b"tengu_plum_vx3", "web search reranking"),
   # (b"tengu_moth_copse", "relevant memory recall"),  # auto-recall; pollutes unrelated convos
   (b"tengu_cork_m4q", "batch command processing"),
]

flip_gates(core_gates + memory_gates + ux_gates + tool_gates)

# --- Bump background agent timeout from 120s to 240s ---

patch(
   "background agent timeout",
   rb'"tengu_auto_background_agents",![01]\)\)return 120000',
   lambda m: m[0].replace(b"120000", b"240000"),
)

# --- Replace usage fetch with self-contained OAuth implementation ---
# FO()/eO() falls back to x-api-key when dA()/nA() returns false (telemetry off),
# but /api/oauth/usage requires Bearer + oauth beta header. Replace the entire
# function with a Deno-native implementation that reads credentials directly.

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
      b"const _u=`${" + config_fn + b"()." + base_url_key + b"}/api/oauth/usage`;"
      b"const _r=(await " + http_client + b".get(_u,{headers:_h,timeout:5000})).data;"
      b'try{Deno.writeTextFileSync(_cp,JSON.stringify(_r))}catch{}'
      b"return _r}"
   )
   data = data.replace(usage_fn_match[0], replacement)
   log("usage fetch: replaced")
else:
   log("usage fetch: pattern NOT FOUND")

Path(sys.argv[1]).write_bytes(data)
