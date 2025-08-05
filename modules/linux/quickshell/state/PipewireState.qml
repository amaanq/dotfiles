pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Tracks and exposes default Pipewire sink/source.
 */
Singleton {
  id: root
  property PwNode defaultSink: Pipewire.defaultAudioSink
  property PwNode defaultSource: Pipewire.defaultAudioSource

  signal sinkProtectionTriggered(string reason)

  PwObjectTracker {
    objects: [defaultSink, defaultSource]
  }

  PwObjectTracker {
    objects: Pipewire.nodes
  }
}
