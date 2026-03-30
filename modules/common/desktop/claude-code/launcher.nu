def detect-platform []: nothing -> string {
   let os = $nu.os-info.name | str downcase
   let arch = $nu.os-info.arch | str downcase

   let norm_arch = match $arch {
      "x86_64" | "x64" | "amd64" => "x64"
      "aarch64" | "arm64" => "arm64"
      _ => { error make { msg: $"unsupported arch: ($arch)" } }
   }

   match $os {
      "linux" => {
         let musl_ld = $"/lib/ld-musl-($arch).so.1"
         let suffix = if ($musl_ld | path exists) { "-musl" } else { "" }
         $"linux-($norm_arch)($suffix)"
      }
      "macos" | "darwin" => $"darwin-($norm_arch)"
      "windows" => { error make { msg: "windows unsupported by this launcher" } }
      _ => { error make { msg: $"unsupported os: ($os)" } }
   }
}

def build-binary [version: string, binary_path: string, cache: string] {
   let platform = detect-platform
   let pkg = $"@anthropic-ai/claude-code-($platform)"
   let tarball_url = $"https://registry.npmjs.org/($pkg)/-/claude-code-($platform)-($version).tgz"

   let tgz_dir = $cache | path join "tgz"
   mkdir $tgz_dir
   let tgz = $tgz_dir | path join $"claude-code-($platform)-($version).tgz"

   if not ($tgz | path exists) {
      print --stderr $"(ansi cyan)fetch:(ansi reset) ($tarball_url)"
      http get --raw $tarball_url | save --force --raw $tgz
   }

   let workdir = $cache | path join $"build-($version)"
   rm -rf $workdir
   mkdir $workdir

   run-external $env._TAR "-xzf" $tgz "-C" $workdir
   let native_bin = $workdir | path join "package" "claude"
   if not ($native_bin | path exists) {
      error make { msg: $"lift: ($native_bin) missing after tar extract" }
   }

   let cli = $workdir | path join "cli.cjs"
   run-external $env._LIFT_SCRIPT $native_bin $cli
   run-external $env._PATCH_SCRIPT $cli

   # Bun's bundler keeps a handful of http/ws/schema libs as runtime-external.
   # Deno has no equivalent provision — drop a package.json next to cli.cjs,
   # resolve deps into a local node_modules/, and bundle that tree into the
   # executable via --include.
   cp --force $env._EXTERNAL_PACKAGE_JSON ($workdir | path join "package.json")

   cd $workdir
   $env.DENO_DIR = ($workdir | path join ".deno")
   run-external $env._DENO "install" "--node-modules-dir=auto"
   run-external $env._DENO "compile" "--allow-all" "--no-check" "--node-modules-dir=auto" "--include=node_modules" "--output" $binary_path "cli.cjs"

   # nushell refuses to delete a directory you're currently inside
   cd $cache
   rm -rf $workdir
}

def main --wrapped [...args] {
   let cache = $env
      | get --optional "XDG_CACHE_HOME"
      | default ($env.HOME | path join ".cache")
      | path join "claude-code"
   mkdir $cache

   let config_dir = $env | get --optional "CLAUDE_CONFIG_DIR" | default (
      $env
         | get --optional "XDG_CONFIG_HOME"
         | default ($env.HOME | path join ".config")
         | path join "claude"
   )
   mkdir $config_dir

   # Sync declarative settings into writable config dir
   cp --force $env._SETTINGS_JSON ($config_dir | path join "settings.json")

   let version = do {
      let version_file = $cache | path join "latest-version"
      let stale = try { (date now) - (ls $version_file | get 0.modified) > 6hr } catch { true }

      if not $stale { return (try { open $version_file } catch { "" }) }

      let version = try {
         http get --max-time 5sec https://registry.npmjs.org/@anthropic-ai/claude-code/latest
            | get version
      } catch {
         print --stderr $"(ansi yellow_bold)warn:(ansi reset) version cache stale, can't re-fetch"
         return ""
      }

      try {
         $version | save --force $version_file
      }
      $version
   }

   let binary_path = if ($version | is-empty) {
      print --stderr $"(ansi yellow_bold)warn:(ansi reset) falling back to latest binary"

      try {
         glob ($cache | path join "claude-*") | sort | last
      } catch {
         print --stderr $"(ansi red_bold)error:(ansi reset) no binary found"
         exit 67
      }
   } else {
      $cache | path join $"claude-($version)"
   }

   if not ($binary_path | path exists) {
      build-binary $version $binary_path $cache
   }

   $env.PATH = ($env.PATH | prepend ($env._RUNTIME_DEPS | split row ":"))
   $env._ENV_JSON | load-env

   exec $binary_path ...$args
}
