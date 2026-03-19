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

data = data.replace(
   b'case"macos":return"/Library/Application Support/ClaudeCode"',
   b'case"macos":return"/etc/claude-code"',
)

# --- Enable hard-disabled slash commands ---

slash_commands: list[tuple[bytes, str]] = [
   (b'name:"btw",description:"Ask a quick side question', "/btw"),
   (b'name:"bridge-kick",description:"Inject bridge failure states', "/bridge-kick"),
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

# --- Bypass thinkback gate ---

patch("thinkback gate", W + rb'\("tengu_thinkback"\)', b'!0||"tengu_thinkback"')

# --- Bypass telemetry gate in feature flag checker ---
# With telemetry off, ed() returns false and all 9 call sites bail out,
# blocking feature flags, GrowthBook refresh, and the async qc() path
# used by remote control. Make ed() always return true so the flag
# infrastructure works even with DISABLE_TELEMETRY=1.

patch(
   "telemetry gate (ed → true)",
   rb"function ed\(\)\{return " + W + rb"\(\)\}",
   lambda m: m[0].replace(b"return ", b"return!0||"),
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
   (b"tengu_bridge_repl_v2", "remote control v2 (envless)"),
   (b"tengu_remote_backend", "remote backend"),
   (b"tengu_keybinding_customization_release", "custom keybindings"),
   (b"tengu_immediate_model_command", "instant /model switching"),
   (b"tengu_fgts", "fine-grained tool streaming"),
   (b"tengu_auto_background_agents", "background agent timeout"),
   (b"tengu_pid_based_version_locking", "PID version locking"),
   (b"tengu_plan_mode_interview_phase", "plan mode interview"),
]

memory_gates: list[Gate] = [
   (b"tengu_session_memory", "session memory"),
   (b"tengu_sm_compact", "memory survives compaction"),
   (b"tengu_compact_cache_prefix", "cache-aware compaction"),
   (b"tengu_compact_streaming_retry", "compact stream retry"),
   (b"tengu_pebble_leaf_prune", "message pruning"),
   (b"tengu_herring_clock", "team memory directory"),
   (b"tengu_passport_quail", "typed combined memory prompts"),
   (b"tengu_swinburne_dune", "new memory extraction prompts"),
]

ux_gates: list[Gate] = [
   (b"tengu_coral_fern", "grep hints in prompt"),
   (b"tengu_kairos_brief", "brief output mode"),
   (b"tengu_permission_explainer", "permission explanations"),
   (b"tengu_destructive_command_warning", "destructive command warnings"),
   (b"tengu_pr_status_cli", "PR status footer"),
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
   (b"tengu_tst_kx7", "auto tool search"),
   (b"tengu_glacier_2xr", "deferred tool improvements"),
   (b"tengu_basalt_3kr", "MCP instruction delta"),
   (b"tengu_cobalt_frost", "voice conversation engine"),
   (b"tengu_scarf_coffee", "API context management"),
   (b"tengu_granite_whisper", "repo file indexing"),
   (b"tengu_plum_vx3", "web search reranking"),
   (b"tengu_quartz_lantern", "remote tool use diff"),
   (b"tengu_marble_anvil", "thinking edits"),
   (b"tengu_moth_copse", "relevant memory recall"),
   (b"tengu_cork_m4q", "batch command processing"),
]

flip_gates(core_gates + memory_gates + ux_gates + tool_gates)

# --- Bump background agent timeout from 120s to 240s ---

patch(
   "background agent timeout",
   rb'"tengu_auto_background_agents",![01]\)\)return 120000',
   lambda m: m[0].replace(b"120000", b"240000"),
)

# --- Kill claude-developer-platform bundled skill ---

data = data.replace(
   b'name:"claude-developer-platform",description:`',
   b'name:"claude-developer-platform",isEnabled:()=>!1,description:`',
)
log("killed claude-developer-platform skill")

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
