#!/usr/bin/env nu

# Rebuild a NixOS / Darwin config.
#
# Modes:
#   ./rebuild.nu                              rebuild the current machine
#   ./rebuild.nu <host>                       rebuild the current machine; <host> must equal $(hostname)
#   ./rebuild.nu <host> --target <ssh-dest>   build locally, deploy the closure to <ssh-dest> via nh --target-host
#   ./rebuild.nu --all                        deploy every reachable NixOS host as root@<host>

def nixos-hosts []: nothing -> list<string> {
   nix eval --json .#nixosConfigurations --apply 'configs: builtins.attrNames configs'
   | from json
   | sort
}

def split-host-list [hosts: string]: nothing -> list<string> {
   if ($hosts | is-empty) {
      []
   } else {
      $hosts | split row "," | str trim | where { $in | is-not-empty }
   }
}

def switch-host [
   host: string
   target: string
   args_split: list<any>
]: nothing -> nothing {
   let flags = nh-os-flags $host $target $args_split

   nh os switch . ...$flags.nh -- ...$flags.nix
}

def nh-os-flags [
   host: string
   target: string
   args_split: list<any>
]: nothing -> record {
   let target_flags = if ($target | is-not-empty) { ["--target-host" $target "--use-substitutes"] } else { [] }
   let nh_flags = (
      ["--hostname" $host]
      | append $target_flags
      | append ($args_split | get 0 | where { $in != "" })
   )

   let nix_flags = [
      "--option" "accept-flake-config" "true"
      "--option" "eval-cache" "false"
   ] | append ($args_split | get --optional 1 | default [])

   {nh: $nh_flags, nix: $nix_flags}
}

def switch-host-captured [
   host: string
   target: string
   args_split: list<any>
]: nothing -> record {
   let flags = nh-os-flags $host $target $args_split

   nh os switch . ...$flags.nh -- ...$flags.nix o+e>| complete
}

def target-statuses [
   target_user: string
   connect_timeout: int
   jobs: int
]: list<string> -> table<host: string, target: string, online: bool> {
   $in
   | par-each --threads $jobs {|host|
      let target = $"($target_user)@($host)"
      let result = (
         ssh
         -o BatchMode=yes
         -o $"ConnectTimeout=($connect_timeout)"
         -o ConnectionAttempts=1
         $target
         true
         | complete
      )

      {
         host: $host
         target: $target
         online: ($result.exit_code == 0)
      }
   }
   | sort-by host
}

def deploy-target [
   target: record<host: string, target: string>
   args_split: list<any>
]: nothing -> record<host: string, exit_code: int> {
   print $"(ansi cyan_bold)deploying(ansi reset) ($target.host) -> ($target.target)"

   let result = switch-host-captured $target.host $target.target $args_split
   if ($result.stdout | str trim | is-not-empty) {
      print $"(ansi blue_bold)==> ($target.host)(ansi reset)"
      print ($result.stdout | str trim)
   }

   if $result.exit_code == 0 {
      print $"(ansi green_bold)done(ansi reset) ($target.host)"
   } else {
      print -e $"(ansi red_bold)failed(ansi reset) ($target.host) exited ($result.exit_code)"
   }

   {
      host: $target.host
      exit_code: $result.exit_code
   }
}

def main --wrapped [
   host: string = ""              # Target NixOS host (defaults to current hostname).
   --target: string = ""          # SSH destination (e.g. root@moraine). Build locally, deploy there.
   --all (-a)                      # Deploy every reachable NixOS host from this flake.
   --jobs (-j): int = 4            # Maximum concurrent SSH checks and deploys for --all.
   --connect-timeout: int = 3      # SSH connect timeout in seconds for --all reachability checks.
   --skip: string = ""            # Comma-separated hosts to skip in --all mode.
   --target-user: string = "root" # SSH user for --all targets.
   --list                          # With --all, print selected hosts and exit.
   ...arguments                   # Extra args for `nh switch` and `nix` (separated by --).
]: nothing -> nothing {
   let current = (hostname | str trim)
   let requested_host = $host
   let host = if ($requested_host | is-empty) { $current } else { $requested_host }
   let args_split = $arguments | prepend "" | split list "--"

   if $all {
      if ($requested_host | is-not-empty) {
         print $"(ansi red_bold)error:(ansi reset) --all does not accept a positional host."
         exit 1
      }

      if ($target | is-not-empty) {
         print $"(ansi red_bold)error:(ansi reset) --all uses --target-user instead of --target."
         exit 1
      }

      if $jobs < 1 {
         print $"(ansi red_bold)error:(ansi reset) --jobs must be at least 1."
         exit 1
      }

      if $connect_timeout < 1 {
         print $"(ansi red_bold)error:(ansi reset) --connect-timeout must be at least 1."
         exit 1
      }

      let skipped = split-host-list $skip
      let hosts = nixos-hosts | where { $in not-in $skipped }

      if ($hosts | is-empty) {
         if $list {
            return
         }

         print $"(ansi red_bold)error:(ansi reset) no NixOS hosts selected."
         exit 1
      }

      let check_jobs = ([$jobs ($hosts | length)] | math min)
      let statuses = $hosts | target-statuses $target_user $connect_timeout $check_jobs
      let targets = $statuses | where online | select host target
      let offline = $statuses | where not online | get host

      if $list {
         print ($targets | each {|target| $"($target.host) -> ($target.target)" } | str join "\n")
         return
      }

      if ($offline | is-not-empty) {
         print -e $"(ansi yellow_bold)skipping offline:(ansi reset) ($offline | str join ', ')"
      }

      if ($targets | is-empty) {
         print $"(ansi red_bold)error:(ansi reset) no reachable NixOS hosts."
         exit 1
      }

      let deploy_jobs = ([$jobs ($targets | length)] | math min)
      print $"(ansi cyan_bold)deploying(ansi reset) ($targets | length) hosts with up to ($deploy_jobs) jobs"

      let results = $targets | par-each --threads $deploy_jobs {|target| deploy-target $target $args_split }
      let failed = $results | where exit_code != 0 | get host

      if ($failed | is-not-empty) {
         print -e $"(ansi red_bold)failed hosts:(ansi reset) ($failed | str join ', ')"
         exit 1
      }

      return
   }

   if $host != $current and ($target | is-empty) {
      print $"(ansi red_bold)error:(ansi reset) refusing to switch '($current)' to the '($host)' configuration."
      print $"  pass --target <ssh-dest> to build locally and deploy remotely, or run this on ($host) itself."
      exit 1
   }

   if (uname | get kernel-name) == "Darwin" {
      let target_flags = if ($target | is-not-empty) { ["--target-host" $target "--use-substitutes"] } else { [] }
      let nh_flags = (
         ["--hostname" $host]
         | append $target_flags
         | append ($args_split | get 0 | where { $in != "" })
      )
      let nix_flags = [
         "--option" "accept-flake-config" "true"
         "--option" "eval-cache" "false"
      ] | append ($args_split | get --optional 1 | default [])

      nh darwin switch . ...$nh_flags -- ...$nix_flags --impure
   } else {
      switch-host $host $target $args_split
   }
}
