{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;

  runtimeDeps = lib.makeBinPath [
    pkgs.ripgrep
    pkgs.bubblewrap
  ];

  # Self-updating launcher: poll GitHub for the latest openai/codex tag
  # every 6h, fetch the prebuilt static-PIE musl tarball on demand, cache
  # per version under $XDG_CACHE_HOME/codex/, and exec. No hashes to bump,
  # no compile step (codex's binaries are signed by openai's CI).
  codex = pkgs.writeScriptBin "codex" /* nu */ ''
    #!${getExe pkgs.nushell} --no-config-file

    def detect-platform []: nothing -> string {
      let arch = match ($nu.os-info.arch | str downcase) {
        "x86_64" | "x64" | "amd64" => "x86_64"
        "aarch64" | "arm64" => "aarch64"
        $arch => {
          print --stderr $"(ansi red_bold)error:(ansi reset) unsupported arch: ($arch)"
          exit 67
        }
      }

      match ($nu.os-info.name | str downcase) {
        "linux" => $"($arch)-unknown-linux-musl"
        "macos" | "darwin" => $"($arch)-apple-darwin"
        $os => {
          print --stderr $"(ansi red_bold)error:(ansi reset) unsupported os: ($os)"
          exit 67
        }
      }
    }

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

      let tag = try {
        http get --max-time 5sec https://api.github.com/repos/openai/codex/releases/latest
          | get tag_name
      } catch {
        print --stderr $"(ansi yellow_bold)warn:(ansi reset) can't fetch latest tag"
        return ""
      }

      # Tag format is `rust-vX.Y.Z`; the 6-char "rust-v" prefix is stable.
      let version = $tag | str substring 6..

      try {
        $version_file | path parse | get parent | mkdir $in
        $version | save --force $version_file
      } catch {
        print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to save latest fetched version"
      }

      $version
    }

    def fetch-binary [version: string, binary_path: string, cache: string] {
      let platform = detect-platform
      let url = $"https://github.com/openai/codex/releases/download/rust-v($version)/codex-($platform).tar.gz"

      let tgz_dir = $cache | path join "tgz"
      mkdir $tgz_dir
      let tgz = $tgz_dir | path join $"codex-($platform)-($version).tgz"

      if not ($tgz | path exists) {
        print --stderr $"(ansi cyan)fetch:(ansi reset) ($url)"
        http get --raw --max-time 120sec $url | save --force --raw $tgz
      }

      let workdir = $cache | path join $"unpack-($version)"
      rm -rf $workdir
      mkdir $workdir

      ^${getExe pkgs.gnutar} -xzf $tgz -C $workdir
      let extracted = $workdir | path join $"codex-($platform)"
      if not ($extracted | path exists) {
        error make { msg: $"fetch: ($extracted) missing after tar extract" }
      }

      mv $extracted $binary_path
      chmod +x $binary_path
      rm -rf $workdir
    }

    def run-latest [--cache: directory, ...arguments] {
      print --stderr $"(ansi yellow_bold)warn:(ansi reset) falling back to latest cached binary"

      try {
        let latest = ls --long ($cache | path join "codex-*")
          | where { $in.type == "file" and ($in.mode | str substring 2..<3) == "x" }
          | sort-by modified
          | last
          | get name
        exec $latest ...$arguments
      } catch {
        print --stderr $"(ansi red_bold)error:(ansi reset) no binary found"
        exit 67
      }
    }

    def --wrapped main [--rebuild, ...args] {
      let rebuild = ($rebuild | default false)
      let cache = $env
        | get --optional "XDG_CACHE_HOME"
        | default ($env.HOME | path join ".cache")
        | path join "codex"
      mkdir $cache

      let version = detect-version --cache $cache --rebuild=$rebuild
      if ($version | is-empty) { run-latest --cache $cache ...$args }

      let binary_path = $cache | path join $"codex-($version)"
      if not ($binary_path | path exists) or $rebuild {
        fetch-binary $version $binary_path $cache
      }

      $env.PATH = ($env.PATH | prepend ("${runtimeDeps}" | split row ":"))
      exec $binary_path ...$args
    }
  '';
in
{
  environment.systemPackages = [ codex ];

  # Codex defaults to ~/.codex; redirect to XDG. The var is read at startup
  # (string "CODEX_HOME points to" appears in the binary), so this is the
  # canonical override -- no command-line flag needed.
  environment.variables.CODEX_HOME = "$XDG_CONFIG_HOME/codex";
}
