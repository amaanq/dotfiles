#!/usr/bin/env nu

# Deploy an ephemeral, rootless circus build agent to a GCC Compile Farm host.
#
#   cfarm-agent cfarm420                  set up + launch the agent
#   cfarm-agent cfarm420 --status         running state + recent log
#   cfarm-agent cfarm420 --stop [--wipe]  kill it (and optionally wipe the seed)

const RUNNER_URL = "circus+tls://circus-agent-rpc.manic.systems:8443"
const TOKEN_RUNTIME = "/run/agenix/circusAgentCfarmToken"
const SUBSTITUTERS = "https://cache.manic.systems https://cache.nixos.org"
const TRUSTED_KEYS = "cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

const CROSS_STATIC_AGENT_EXPR = r#'
let
  f = builtins.getFlake "github:manic-systems/circus/@REV@";
  pkgs = import f.inputs.nixpkgs {
    localSystem = builtins.currentSystem;
    crossSystem = @CROSS@;
  };
  craneLib = f.inputs.crane.mkLib pkgs;
  staticArgs = {
    pname = "circus-agent-static";
    src = f.outPath;
    strictDeps = true;
    nativeBuildInputs = with pkgs.buildPackages; [ pkg-config capnproto ];
    cargoExtraArgs = "--package circus-agent";
    doCheck = false;
    CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
    hardeningDisable = [ "fortify" "fortify3" ];
  };
in craneLib.buildPackage (staticArgs // { cargoArtifacts = craneLib.buildDepsOnly staticArgs; })
'#

def nix-system [machine: string]: nothing -> string {
   match $machine {
      "x86_64" => "x86_64-linux"
      "aarch64" | "arm64" => "aarch64-linux"
      "ppc64le" | "powerpc64le" => "powerpc64le-linux"
      "ppc64" | "powerpc64" => "powerpc64-linux"
      "riscv64" => "riscv64-linux"
      "mips64" => "mips64-linux"
      "loongarch64" => "loongarch64-linux"
      _ => { error make { msg: $"unsupported cfarm arch: ($machine)" } }
   }
}

# Nix system -> musl crossSystem attrset (as a Nix literal). BE ppc64 needs an
# explicit elfv2 ABI or gcc defaults to ELFv1 and the toolchain build fails.
def musl-cross [system: string]: nothing -> string {
   match $system {
      "x86_64-linux" => '{ config = "x86_64-unknown-linux-musl"; }'
      "aarch64-linux" => '{ config = "aarch64-unknown-linux-musl"; }'
      "powerpc64le-linux" => '{ config = "powerpc64le-unknown-linux-musl"; }'
      "powerpc64-linux" => '{ config = "powerpc64-unknown-linux-musl"; gcc = { abi = "elfv2"; }; }'
      "riscv64-linux" => '{ config = "riscv64-unknown-linux-musl"; }'
      "mips64-linux" => '{ config = "mips64-unknown-linux-muslabi64"; }'
      "loongarch64-linux" => '{ config = "loongarch64-unknown-linux-musl"; }'
      _ => { error make { msg: $"no musl cross for ($system)" } }
   }
}

# Nix system -> glibc cross triple for the seed nix (cross-built nix substitutes
# from cache.nixos.org; native/emulated would rebuild its whole closure). BE
# ppc64 uses the gnuabielfv2 variant so the seed is ELFv2 too.
def gnu-triple [system: string]: nothing -> string {
   match $system {
      "aarch64-linux" => "aarch64-unknown-linux-gnu"
      "powerpc64le-linux" => "powerpc64le-unknown-linux-gnu"
      "powerpc64-linux" => "powerpc64-unknown-linux-gnuabielfv2"
      "riscv64-linux" => "riscv64-unknown-linux-gnu"
      "mips64-linux" => "mips64-unknown-linux-gnuabi64"
      "loongarch64-linux" => "loongarch64-unknown-linux-gnu"
      _ => { error make { msg: $"no gnu cross triple for ($system)" } }
   }
}

def static-agent-flakeref [rev: string, system: string]: nothing -> string {
   $"github:manic-systems/circus/($rev)#packages.($system).circus-agent-static"
}

def build-static-agent [rev: string, system: string, local_sys: string]: nothing -> string {
   if $system == $local_sys {
      print "building static agent (upstream) ..."
      ^nix build (static-agent-flakeref $rev $system) --no-link --print-out-paths | str trim
   } else {
      print $"cross-building static agent for ($system) ..."
      let expr = ($CROSS_STATIC_AGENT_EXPR | str replace --all "@REV@" $rev | str replace --all "@CROSS@" (musl-cross $system))
      ^nix build --impure --no-link --print-out-paths --expr $expr | str trim
   }
}

def seed-closure-expr [rev: string, system: string, local_sys: string]: nothing -> string {
   if $system == $local_sys {
      $"let f = builtins.getFlake \"github:manic-systems/circus/($rev)\"; p = import f.inputs.nixpkgs { system = \"($system)\"; }; in [ p.nix p.cacert ]"
   } else {
      $"let f = builtins.getFlake \"github:manic-systems/circus/($rev)\"; p = import f.inputs.nixpkgs { localSystem = \"($local_sys)\"; crossSystem = { config = \"(gnu-triple $system)\"; }; }; in [ p.nix p.cacert ]"
   }
}

# Walk up from the script to the flake root, so it works from any cwd.
def find-root [] {
   mut dir = $env.FILE_PWD
   loop {
      if ($dir | path join flake.nix | path exists) { return $dir }
      let parent = ($dir | path dirname)
      if $parent == $dir { break }
      $dir = $parent
   }
   error make { msg: $"cfarm-agent: no flake.nix above ($env.FILE_PWD)" }
}

def main [
   host: string                                   # cfarm ssh host, e.g. cfarm420
   --max-jobs: int = 0                            # concurrent builds (0 = min(ram/2, threads))
   --features: string = "big-parallel benchmark"  # nix system-features to advertise
   --token: string = ""                           # override the agenix token
   --status                                       # report state + recent log, then exit
   --stop                                         # kill the agent, then exit
   --wipe                                         # with --stop, also delete the seeded store
]: nothing -> nothing {
   let home = (^ssh $host 'echo $HOME' | str trim)
   if ($home | is-empty) {
      print $"(ansi red_bold)error:(ansi reset) couldn't reach ($host) over ssh"
      exit 1
   }
   let bindir = $"($home)/cfarm-agent"
   let datadir = $"($home)/.local/share/circus-agent"
   # [c] keeps the pattern from matching the shell that carries it.
   let pat = $"($bindir)/bin/[c]ircus-agent"

   if $status {
      let running = (^ssh $host $"pgrep -af '($pat)' | cat" | str trim)
      let state = if ($running | is-empty) { $"(ansi yellow)not running(ansi reset)" } else { $"(ansi green)running(ansi reset)\n($running)" }
      print $"($host): ($state)"
      print "--- recent log ---"
      ^ssh $host $"tail -n 30 ($bindir)/agent.log 2>/dev/null | cat"
      return
   }

   if $stop {
      ^ssh $host $"pkill -f '($pat)' ; true"
      print $"($host): agent stopped"
      if $wipe {
         ^ssh $host $"chmod -R u+w ($datadir) 2>/dev/null ; rm -rf ($datadir) ($bindir)"
         print $"($host): seeded store + bin removed"
      }
      return
   }

   # One round-trip for every host fact: arch, threads, RAM, and whether plain +
   # nested user namespaces work (nix nests one inside the agent's own).
   let facts = (^ssh $host '
      uname -m
      nproc
      grep MemTotal /proc/meminfo
      u() { unshare --user --map-root-user "$@" >/dev/null 2>&1; }
      u true && echo y || echo n
      u --mount sh -c "unshare --user --map-root-user true" && echo y || echo n
      timeout 3 getent hosts circus-agent-rpc.manic.systems >/dev/null 2>&1 && echo y || echo n
   ' | lines | each { str trim })
   let machine = $facts.0
   let system = (nix-system $machine)
   let threads = ($facts.1 | into int)
   let mem_gib = ($facts.2 | split row -r '\s+' | get 1 | into int) / (1024 * 1024)

   if $facts.3 != "y" {
      print $"(ansi red_bold)error:(ansi reset) ($host) has unprivileged user namespaces disabled; the rootless sandbox can't run there"
      exit 1
   }
   let sandbox = ($facts.4 == "y")
   if not $sandbox {
      print $"(ansi yellow)note:(ansi reset) ($host) refuses nested user namespaces; disabling the nix build sandbox"
   }
   let dns_broken = ($facts.5 == "n")

   let jobs = if $max_jobs > 0 {
      $max_jobs
   } else {
      # ~2 GiB per build, capped at the core count, floor 1.
      [1 ([(($mem_gib / 2) | math ceil | into int) $threads] | math min)] | math max
   }
   print $"(ansi cyan)($host)(ansi reset): ($machine) -> ($system), ($jobs) jobs"

   let rev = (open (find-root | path join ".tack" "pins.lock.json") | get circus.rev)
   let local_sys = (^nix eval --impure --raw --expr 'builtins.currentSystem')
   let agent_out = (build-static-agent $rev $system $local_sys)

   print "building seed closure (nix + cacert) ..."
   let seed_expr = (seed-closure-expr $rev $system $local_sys)
   let seed_outs = (^nix build --impure --no-link --print-out-paths --expr $seed_expr | lines)
   let nix_out = ($seed_outs | where { ($in | path join "bin" "nix" | path exists) } | first)
   let closure = (^nix path-info -r ...$seed_outs | lines)

   print "seeding store + binary ..."
   ^ssh $host $"mkdir -p ($bindir)/bin ($bindir)/work ($datadir)/store ($datadir)/etc/nix"
   ^ssh $host $"test -s ($bindir)/work/machine_id || cat /proc/sys/kernel/random/uuid > ($bindir)/work/machine_id"
   ^rsync -a $"($agent_out)/bin/circus-agent" $"($host):($bindir)/bin/circus-agent"
   ^rsync -a --info=progress2 -h --ignore-existing ...$closure $"($host):($datadir)/store/"

   let nix_conf = [
      "experimental-features = nix-command flakes"
      $"substituters = ($SUBSTITUTERS)"
      $"trusted-public-keys = ($TRUSTED_KEYS)"
      "build-users-group ="
      $"sandbox = ($sandbox | into string)"
   ] | str join "\n"
   $nix_conf | ^ssh $host $"cat > ($datadir)/etc/nix/nix.conf"

   {
      agent: {
         name: $host
         auth_token: ""
         runner_url: $RUNNER_URL
         systems: [$system]
         supported_features: ($features | split row ' ')
         max_jobs: $jobs
         rootless: true
         rootless_data_dir: $datadir
         work_dir: $"($bindir)/work"
      }
   } | to toml | ^ssh $host $"cat > ($bindir)/agent.toml"

   let tok = if ($token | is-not-empty) {
      $token
   } else {
      let f = ($env.CFARM_AGENT_TOKEN_FILE? | default $TOKEN_RUNTIME)
      if not ($f | path exists) {
         print $"(ansi red_bold)error:(ansi reset) no token at ($f); rebuild + `nix run .#rekey` to activate it, or pass --token."
         exit 1
      }
      open --raw $f | str trim
   }

   if $dns_broken {
      print $"(ansi yellow)note:(ansi reset) ($host) has broken DNS; resolving runner IP locally and wrapping in mount namespace"
      let runner_host = "circus-agent-rpc.manic.systems"
      let runner_ip = (^getent hosts $runner_host | split row -r '\s+' | first)
      ^ssh $host $"printf '($runner_ip) ($runner_host)\n' > ($bindir)/hosts; cat /etc/hosts >> ($bindir)/hosts 2>/dev/null; printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > ($bindir)/resolv.conf"
   }

   print "launching ..."
   let agent_exec = if $dns_broken {
      $"setsid unshare -Urm sh -c 'mount --bind ($bindir)/hosts /etc/hosts && mount --bind ($bindir)/resolv.conf /etc/resolv.conf && exec ($bindir)/bin/circus-agent -c ($bindir)/agent.toml' </dev/null >($bindir)/agent.log 2>&1 &\nsleep 1"
   } else {
      $"setsid -f ($bindir)/bin/circus-agent -c ($bindir)/agent.toml >($bindir)/agent.log 2>&1 </dev/null"
   }
   let launch_lines = [
      "#!/usr/bin/env bash"
      "set -e"
      "IFS= read -r CIRCUS_AGENT_TOKEN; export CIRCUS_AGENT_TOKEN"
      $"export CIRCUS_AGENT_NIX=($nix_out)/bin/nix"
      $"pkill -f ($bindir)/bin/circus-agent 2>/dev/null || true"
      $agent_exec
      "echo launched"
   ]
   $launch_lines | str join "\n" | ^ssh $host $"cat > ($bindir)/launch.sh"
   $"($tok)\n" | ^ssh $host $"bash ($bindir)/launch.sh"

   sleep 4sec
   print "--- agent.log ---"
   ^ssh $host $"tail -n 25 ($bindir)/agent.log 2>/dev/null | cat"
   print $"\n(ansi green)deployed(ansi reset). cfarm-agent ($host) --status  |  --stop [--wipe]"
}
