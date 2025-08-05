pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property real nightLightKelvin: 6000
  property bool needUpdate: false

  function setIntensity(perc) {
    const low_k = 2500;
    const high_k = 6500;

    let inverse_x = (100 - perc) / 100.0;

    const kelv = (high_k - low_k) * inverse_x + low_k;

    nightLightKelvin = kelv;
    needUpdate = true;
    updateTimer.running = true;
  }

  Process {
    id: hyprctlUpdateProc
    running: false
  }

  Process {
    id: hyprsunsetProc
    running: true
    command: ["hyprsunset", "-i"]
  }

  Timer {
    id: updateTimer
    interval: 100
    repeat: true
    running: false

    onTriggered: () => {
      if (hyprctlUpdateProc.running || !needUpdate)
        return;

      needUpdate = false;

      if (!C.Config.misc.nightLightEnabled) {
        hyprctlUpdateProc.command = ["hyprctl", "hyprsunset", "identity"];
        hyprctlUpdateProc.running = true;

        updateTimer.running = false;
        return;
      }

      if (nightLightKelvin < 2500)
        nightLightKelvin = 2500;
      if (nightLightKelvin > 4000)
        nightLightKelvin = 4000;

      hyprctlUpdateProc.command = ["hyprctl", "hyprsunset", "temperature", "" + nightLightKelvin];
      hyprctlUpdateProc.running = true;

      updateTimer.running = false;
    }
  }
}
