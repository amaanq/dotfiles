#!/usr/bin/env nu

# Rebuild a NixOS / Darwin config.
#
# Modes:
#   ./rebuild.nu                              rebuild the current machine
#   ./rebuild.nu <host>                       rebuild the current machine; <host> must equal $(hostname)
#   ./rebuild.nu <host> --target <ssh-dest>   build locally, deploy the closure to <ssh-dest> via nh --target-host
#
# Hard-refuses to switch the local machine to a config whose hostname differs
# from the running one — that's how a laptop once got switched to a server
# config. The mismatch case ALWAYS requires --target, which is also what makes
# the build local and the push remote (nh handles the copy + activation over
# SSH). There is no longer a "build on the remote" mode.
def main --wrapped [
  host: string = ""              # Target NixOS host (defaults to current hostname).
  --target: string = ""          # SSH destination (e.g. root@moraine). Build locally, deploy there.
  ...arguments                   # Extra args for `nh switch` and `nix` (separated by --).
]: nothing -> nothing {
   let current = (hostname | str trim)
   let host = if ($host | is-empty) { $current } else { $host }

   if $host != $current and ($target | is-empty) {
      print $"(ansi red_bold)error:(ansi reset) refusing to switch '($current)' to the '($host)' configuration."
      print $"  pass --target <ssh-dest> to build locally and deploy remotely, or run this on ($host) itself."
      exit 1
   }

   let args_split = $arguments | prepend "" | split list "--"

   let target_flags = if ($target | is-not-empty) { ["--target-host" $target] } else { [] }
   let nh_flags = (
      ["--hostname" $host]
      | append $target_flags
      | append ($args_split | get 0 | where { $in != "" })
   )

   let nix_flags = [
      "--option" "accept-flake-config" "true"
      "--option" "eval-cache" "false"
   ] | append ($args_split | get --optional 1 | default [])

   if (uname | get kernel-name) == "Darwin" {
      nh darwin switch . ...$nh_flags -- ...$nix_flags --impure
   } else {
      nh os switch . ...$nh_flags -- ...$nix_flags
   }
}
