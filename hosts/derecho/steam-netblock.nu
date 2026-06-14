const cg = "/sys/fs/cgroup/netblock"
const procs = ["steam", "steamwebhelper"]

def table-exists [] { (^nft list table inet netblock | complete).exit_code == 0 }

def state [] {
   if (table-exists) { "ON" } else { "OFF" }
}

def pids-for [name: string] {
   ^pgrep -x $name | complete | get stdout | lines | where {|l| ($l | str trim) != "" }
}

def held-pids [] {
   ^cat $"($cg)/cgroup.procs" | lines | where {|l| ($l | str trim) != "" }
}

def move-pid [pid: string, dest: string] {
   $pid | ^tee $dest | ignore
}

def split-hostport [addr: string] {
   $addr | parse -r '^\[?(?<host>.+?)\]?:(?<port>\d+)$' | first
}

def loopback? [addr: string] { ($addr | str starts-with "127.") or ($addr | str starts-with "[::1]") }

def kill-external-socks [] {
   let pids = (held-pids)
   let rows = (
      ^ss -tnpH state established
         | lines
         | each {|l| $l | split row -r '\s+' | where {|x| $x != "" } }
         | where {|f| ($f | length) >= 5 }
   )
   for f in $rows {
      let peer = ($f | get 3)
      if (loopback? $peer) { continue }
      let sockpids = (
         $f | get 4 | parse -r 'pid=(?<p>\d+)' | get p
      )
      if not ($sockpids | any {|p| $p in $pids }) { continue }
      let l = (split-hostport ($f | get 2))
      let p = (split-hostport $peer)
      ^ss -K dst $p.host dport "=" $p.port src $l.host sport "=" $l.port | ignore
   }
}

def setup [] {
   if not ($cg | path exists) { mkdir $cg }
   if not (table-exists) {
      ^nft add table inet netblock
      ^nft add chain inet netblock out "{ type filter hook output priority 0; }"
      ^nft add rule inet netblock out socket cgroupv2 level 1 '"netblock"' oifname != lo drop
   }
}

def block-on [] {
   setup
   mut moved = 0
   for name in $procs {
      for pid in (pids-for $name) {
         move-pid $pid $"($cg)/cgroup.procs"
         $moved = $moved + 1
      }
   }
   kill-external-socks
   print $"netblock ON: severed ($moved) process\(es\)"
}

def block-off [] {
   let f = $"($cg)/cgroup.procs"
   if ($f | path exists) {
      for pid in (^cat $f | lines | where {|l| ($l | str trim) != "" }) { move-pid $pid "/sys/fs/cgroup/cgroup.procs" }
   }
   do { ^nft delete table inet netblock } | complete | ignore
   print "netblock OFF: network restored"
}

# Sever the Steam client's network
def "main on" [] { block-on }

# Restore the Steam client's network
def "main off" [] { block-off }

# Report whether netblock is currently ON or OFF
def "main status" [] {
   if (table-exists) {
      let held = (^cat $"($cg)/cgroup.procs" | lines | str join " ")
      print $"ON: ($held)"
   } else { print "OFF" }
}

# Flip netblock between ON and OFF
def "main toggle" [] {
   if (state) == "ON" { block-off } else { block-on }
}

def main [] { main toggle }
