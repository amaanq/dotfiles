def state-file [] {
   $env.XDG_RUNTIME_DIR | path join "voxtype" "discord-mic-state"
}

def load-state [] {
   let file = (state-file)
   if ($file | path exists) {
      open --raw $file | from nuon
   } else { [] }
}

def discord-nodes [] {
   let dump = (^pw-dump | complete)
   if $dump.exit_code != 0 { return [] }
   $dump.stdout | from json | where {|n| $n.type? == "PipeWire:Interface:Node" } | each {|n| $n.info?.props? } | where {|p|
      (
         $p."media.class"? == "Stream/Input/Audio"
         and $p."object.id"? != null
         and $p."application.process.id"? != null
      )
   } | where {|p|
      let cmdline = (do -i { open --raw $"/proc/($p."application.process.id")/cmdline" | decode utf-8 })
      $cmdline | default "" | str contains "/web-apps/discord-web-app"
   } | each {|p| {id: $p."object.id"} }
}

def set-mute [id: int, muted: bool] {
   ^wpctl set-mute $id (if $muted { 1 } else { 0 }) | complete | ignore
}

# Mute Discord's capture streams, remembering each stream's prior mute state
def "main mute" [] {
   let nodes = (discord-nodes)
   let state = (load-state)
   let new = ($nodes | where {|n| $n.id not-in ($state | get id) } | each {|n|
         let volume = (^wpctl get-volume $n.id | complete)
         if $volume.exit_code == 0 {
            {id: $n.id, was_muted: ($volume.stdout | str contains "[MUTED]")}
         }
      })
   let state = ($state | append $new)
   $state | to nuon | save -f (state-file)
   for n in ($nodes | where {|n| $n.id in ($state | get id) }) { set-mute $n.id true }
}

# Restore each remembered stream to its pre-mute state
def "main restore" [] {
   let file = (state-file)
   if not ($file | path exists) { return }
   let current = (discord-nodes | get id)
   for n in (load-state | where {|n| $n.id in $current }) { set-mute $n.id $n.was_muted }
   rm -f $file | ignore
}

def main [] {
   print -e "usage: voxtype-discord-mic {mute|restore}"
   exit 2
}
