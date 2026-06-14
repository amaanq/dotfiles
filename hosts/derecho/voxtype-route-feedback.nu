def audio-nodes []: nothing -> list<record> {
   let dump = (^pw-dump | complete)
   if $dump.exit_code != 0 { error make {
      msg: $'pw-dump failed: ($dump.stderr | str trim)'
   } }

   $dump.stdout
      | from json
      | where {|node| $node.type? == 'PipeWire:Interface:Node' }
      | each {|node| $node.info?.props? }
      | where {|props| $props != null }
}

def main [] {
   for _ in 1..50 {
      let nodes = (audio-nodes)
      let bus = try {
         $nodes | where {|node| $node."node.name"? == 'Discord-Bus' } | first
      } catch { null }
      let feedback = ($nodes | where {|node|
            (
               $node."node.name"? == 'alsa_playback.voxtype'
               and $node."media.class"? == 'Stream/Output/Audio'
            )
         })

      if $bus != null and not ($feedback | is-empty) {
         for stream in $feedback {
            let route = (^pw-metadata -n default $stream."object.id" target.object $bus."object.serial" Spa:Id
               | complete)
            if $route.exit_code != 0 { error make {
               msg: $'pw-metadata failed: ($route.stderr | str trim)'
            } }
         }
         return
      }

      sleep 100ms
   }

   error make {msg: 'Voxtype feedback stream or Discord-Bus did not appear within five seconds'}
}
