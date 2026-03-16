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
      let deno_dir = $cache | path join ".deno"
      let pkg = $"npm:@anthropic-ai/claude-code@($version)"
      $env.DENO_DIR = $deno_dir
      run-external $env._DENO "cache" $pkg
      run-external $env._PATCH_SCRIPT ($deno_dir
         | path join "npm" "registry.npmjs.org" "@anthropic-ai" "claude-code" $version "cli.js")
      run-external $env._DENO "compile" "--allow-all" "--output" $binary_path $pkg
      rm -rf $deno_dir
   }

   $env.PATH = ($env.PATH | prepend ($env._RUNTIME_DEPS | split row ":"))
   $env._ENV_JSON | load-env

   exec $binary_path ...$args
}
