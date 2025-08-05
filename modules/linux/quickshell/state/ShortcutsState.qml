pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
  id: root
  property list<var> binds

  function modListForMask(mask) {
    const mods = [
      {
        bit: 1 << 0,
        name: "SHIFT"
      },
      {
        bit: 1 << 1,
        name: "CAPS"
      },
      {
        bit: 1 << 2,
        name: "CTRL"
      },
      {
        bit: 1 << 3,
        name: "ALT"
      },
      {
        bit: 1 << 4,
        name: "MOD2"
      },
      {
        bit: 1 << 5,
        name: "MOD3"
      },
      {
        bit: 1 << 6,
        name: "SUPER"
      },
      {
        bit: 1 << 7,
        name: "MOD5"
      },
    ];
    let result = [];
    for (let i = 0; i < mods.length; ++i) {
      if (mask & mods[i].bit)
        result.push(mods[i].name);
    }
    return result;
  }

  function fetchKeybinds() {
    getKeybinds.running = true;
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name == "configreloaded") {
        root.fetchKeybinds();
      }
    }
  }

  Process {
    id: getKeybinds
    running: true
    command: ["hyprctl", "binds", "-j"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.length === 0)
          return;
        root.binds = JSON.parse(text);
      }
    }
  }
}
