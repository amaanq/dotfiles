from __future__ import annotations

# Extract the cli.js bundle from a bun --compile --bytecode executable.
#
# Starting with @anthropic-ai/claude-code 2.1.113 the npm package stopped
# shipping cli.js and instead publishes platform-specific tarballs that contain
# a bun-compiled ELF (~226 MB). The JavaScript is still fully embedded in the
# binary as plaintext — the @bytecode marker just means a V8 parse-cache lives
# alongside it, not instead of it.
#
# Layout of each CJS module inside the bun SEA payload:
#   // @bun[ @bytecode] @bun-cjs\n
#   (function(exports, require, module, __filename, __dirname) {<BODY>})\n
#   \x00/$bunfs/root/<next-module-name>\x00...
#
# Claude Code ships three real modules in the tail region (past 0x6000000):
# the main cli (~12 MB), then two tiny native-loader stubs for the optional
# image-processor.node and audio-capture.node. Only the first is interesting.

import sys
from pathlib import Path

# Skip over .rodata / .text — those contain `// @bun` string literals (error
# messages, help text) that would confuse the scanner. The first real module
# sat at ~0xd333ec8 in 2.1.113; staying well below that survives future growth.
SCAN_FROM: int = 0x6000000

HEADERS: list[bytes] = [
    b"// @bun @bytecode @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
    b"// @bun @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
]

CJS_OPEN: bytes = b"(function(exports, require, module, __filename, __dirname) {"
CJS_END: bytes = b"})\n\x00"


def find_main_module(data: bytes) -> tuple[int, int]:
    # In 2.1.117 bun emits cli.js twice: once as a @bytecode blob with the V8
    # parse cache interleaved between the source and its `})\n\x00` terminator,
    # and again as a clean source-only copy that terminates normally. Collect
    # every header past SCAN_FROM and pick the first one whose terminator lies
    # before the next header — that's the source-only copy.
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
    # tail is either `})\n` or `})`
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

    # Sanity: the real claude-code cli.js always contains this legal banner.
    if b"Anthropic" not in body[:4096]:
        sys.exit("lift: extracted body is missing Anthropic banner — layout changed?")

    output.write_bytes(body)
    sys.stderr.write(
        f"lifted {len(body):,} bytes from {binary.name} "
        f"(module @ {start:#x}..{end:#x}) -> {output}\n"
    )


if __name__ == "__main__":
    main()
