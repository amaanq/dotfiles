{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;
in
{
  # Self-updating launcher generator for slop coding agents.
  # This is exposed via `_module.args` so the sibling modules
  # can take `mkSlopLauncher` directly in their function arg list.
  #
  # Each tool plugs in:
  #
  #   - name:           script name + binary file prefix.
  #   - cacheSubdir:    optional, defaults to name. Subdir under
  #                     $XDG_CACHE_HOME for cached binaries + version probe.
  #   - versionUrl:     HTTP endpoint returning JSON.
  #   - versionParser:  single-line nu pipeline applied to the parsed JSON
  #                     to extract the version string. Examples:
  #                       "get version"                              (npm)
  #                       "get tag_name | str substring 6.."         (codex)
  #                       "get tag_name | str trim --left --char v"  (opencode)
  #   - fetch:          nu code body. Receives `$version`, `$binary_path`,
  #                     `$cache` in scope. Must produce an executable file
  #                     at `$binary_path`.
  #   - runtimeDeps:    list of derivations whose `/bin` is prepended to
  #                     PATH at exec time.
  #   - preExec:        optional nu code spliced between PATH setup and
  #                     `exec`. Has access to all of main's locals.
  #
  # Common machinery: 6h-cached version probe with `--rebuild` bypass,
  # newest-cached fallback when the network is gone, --wrapped main that
  # forwards extra args.
  _module.args.mkSlopLauncher =
    {
      name,
      versionUrl,
      versionParser,
      fetch,
      runtimeDeps ? [ ],
      preExec ? "",
      cacheSubdir ? name,
    }:
    pkgs.writeScriptBin name /* nu */ ''
      #!${getExe pkgs.nushell} --no-config-file

      def detect-version [--cache: directory, --rebuild]: nothing -> string {
        let version_file = $cache | path join "latest-version"
        let rebuild = ($rebuild | default false)
        let stale = try { (date now) - (ls $version_file | get 0.modified) > 6hr } catch { true }

        if not ($rebuild or $stale) {
          return (try {
            open $version_file
          } catch {
            print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to read latest fetched version"
            ""
          })
        }

        let version = try {
          http get --max-time 5sec ${versionUrl} | ${versionParser}
        } catch {
          print --stderr $"(ansi yellow_bold)warn:(ansi reset) can't fetch latest version"
          return ""
        }

        try {
          $version_file | path parse | get parent | mkdir $in
          $version | save --force $version_file
        } catch {
          print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to save latest fetched version"
        }

        $version
      }

      # Find newest cached binary path. Returns "" if none. Includes
      # symlinks because some tools (opencode) cache binaries via
      # `ln -s` to a nix-build gcroot, where the mode field reads
      # `lrwxrwxrwx` and the exec-bit check would reject it. A broken
      # symlink would still fail at exec time.
      def latest-cached [--cache: directory]: nothing -> string {
        try {
          ls --long ($cache | path join "${name}-*")
            | where {
                ($in.type == "file" and ($in.mode | str substring 2..<3) == "x")
                or ($in.type == "symlink")
              }
            | sort-by modified
            | last
            | get name
        } catch { "" }
      }

      def fetch-binary [version: string, binary_path: string, cache: string] {
        ${fetch}
      }

      def --wrapped main [--rebuild, ...args] {
        let rebuild = ($rebuild | default false)
        let cache = $env
          | get --optional "XDG_CACHE_HOME"
          | default ($env.HOME | path join ".cache")
          | path join "${cacheSubdir}"
        mkdir $cache

        let version = detect-version --cache $cache --rebuild=$rebuild

        # Resolve to a binary path. Both branches converge on the same
        # PATH/preExec/exec sequence below so offline-fallback isn't a
        # special codepath that skips environment setup (config syncing,
        # hook installation, etc).
        let binary_path = if ($version | is-empty) {
          print --stderr $"(ansi yellow_bold)warn:(ansi reset) version probe failed, trying latest cached binary"
          latest-cached --cache $cache
        } else {
          let p = $cache | path join $"${name}-($version)"
          if not ($p | path exists) or $rebuild {
            fetch-binary $version $p $cache
          }
          $p
        }

        if ($binary_path | is-empty) {
          print --stderr $"(ansi red_bold)error:(ansi reset) no binary available (network down + nothing cached)"
          exit 67
        }

        $env.PATH = ($env.PATH | prepend ("${lib.makeBinPath runtimeDeps}" | split row ":"))
        ${preExec}
        exec $binary_path ...$args
      }
    '';
}
