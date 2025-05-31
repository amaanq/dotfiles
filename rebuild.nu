#!/usr/bin/env nu

def --wrapped sync [...arguments] {
  (rsync
    --rsh "ssh"
    --compress
    --delete --recursive --force
    --delete-excluded
    --delete-missing-args
    ...$arguments)
}

# Rebuild a NixOS / Darwin config.
def main --wrapped [
  host: string = "" # The host to build.
  --remote (-r)     # Whether if this is a remote host. The config will be built on this host if it is.
  ...arguments      # The arguments to pass to `nh os switch` and `nix` (separated by --).
]: nothing -> nothing {
  let host = if ($host | is-not-empty) {
    if $host != (hostname) and not $remote {
      print $"(ansi yellow_bold)warn:(ansi reset) building local configuration for hostname that does not match the local machine"
    }

    $host
  } else if $remote {
    print $"(ansi red_bold)error:(ansi reset) hostname not specified for remote build"
    exit 1
  } else {
    "nixmain" # Default hostname for this config
  }

  if $remote {
    ssh -tt $host $"
      rm --recursive --force dotfiles
    "

    git ls-files
    | sync --files-from - ./ ($host + ":dotfiles")

    ssh -tt $host $"
      cd dotfiles
      ./rebuild.nu ($host) ($arguments | str join ' ')
    "

    return
  }

  let args_split = $arguments | prepend "" | split list "--"
  let nh_flags = [
    "--hostname" $host
  ] | append ($args_split | get 0 | filter { $in != "" })

  let nix_flags = [
    "--option" "accept-flake-config" "true"
    "--option" "eval-cache"          "false"
  ] | append ($args_split | get --ignore-errors 1 | default [])

  nh os switch . ...$nh_flags -- ...$nix_flags
}
