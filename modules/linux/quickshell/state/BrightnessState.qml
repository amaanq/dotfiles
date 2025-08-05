pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../config" as C

Singleton {
  id: root
  // FIXME: fox fix this. We need to update when the monitors change.
  property list<string> monitors: Quickshell.screens.map(x => {
    return x.name;
  })
  property list<real> monitorsDdcBuses
  property list<real> brightnesses
  property list<bool> needUpdate
  property bool hasBacklight: false
  property bool backlightNeedUpdate: false
  property real backlightBrightness: -1
  property real overallBrightness: 50
  property bool anyControls: monitorsDdcBuses.filter(x => {
    return x != -1;
  }).length > 0 || hasBacklight

  property real cyclingDdcIndex: 0

  function load() {
  // Dummy func to force init lazy singleton
  }

  function setBrightness(monitorId, brightness) {
    if (brightnesses[monitorId] == -1)
      return; // unsupported display

    needUpdate[monitorId] = true;
    brightnesses[monitorId] = brightness;
    updateTimer.running = true;
  }

  function setOverall(brightness) {
    setBacklight(brightness);
    for (let i = 0; i < monitors.length; ++i) {
      setBrightness(i, brightness);
    }
    overallBrightness = brightness;
  }

  function setBacklight(brightness) {
    if (backlightBrightness == -1)
      return; // unsupported display

    backlightNeedUpdate = true;
    backlightBrightness = brightness;
    updateTimer.restart();
  }

  function incrementActive(delta) {
    const focusedMonitorId = Hyprland.focusedMonitor.id;
    if (C.Config.misc.brightnessSplit) {
      brightnesses[focusedMonitorId] += delta;
      needUpdate[focusedMonitorId] = true;
      updateTimer.running = true;
    } else {
      setOverall(overallBrightness + delta);
    }
  }

  Process {
    id: ddcVcpProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        brightnesses[cyclingDdcIndex] = parseInt(data.split(" ")[3]);
        overallBrightness = brightnesses[cyclingDdcIndex];
        for (let i = cyclingDdcIndex + 1; i < monitorsDdcBuses.length; ++i) {
          if (monitorsDdcBuses[i] < 0)
            continue;
          console.log("Cycling to next DDC bus: " + monitorsDdcBuses[i]);
          ddcVcpProc.command = ["ddcutil", "getvcp", "10", "--bus", "" + monitorsDdcBuses[i], "--brief"];
          cyclingDdcIndex = i;
          ddcVcpNextTimer.restart();
          return;
        }
        cyclingDdcIndex = 0;
      }
    }
  }

  Process {
    id: ddcUpdateProc
    running: false
  }

  Process {
    id: backlightUpdateProc
    running: false
  }

  Process {
    id: backlightGetValueProc
    running: false
    command: ["sh", "-c", "echo \"$(brightnessctl g) $(brightnessctl m)\""]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const s = data.split(" ");
        backlightBrightness = (parseInt(s[0]) * 100.0) / (parseInt(s[1]) * 1.0);
      }
    }
  }

  Process {
    id: backlightProc
    running: true
    command: ["brightnessctl", "--list"]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        hasBacklight = data.indexOf("class \'backlight\'") != -1;
        if (hasBacklight)
          backlightGetValueProc.running = true;
      }
    }
  }

  Timer {
    id: updateTimer
    interval: 10
    repeat: true
    running: false

    onTriggered: () => {
      if (ddcUpdateProc.running)
        return;

      if (backlightUpdateProc.running)
        return;

      if (backlightNeedUpdate) {
        backlightUpdateProc.command = ["brightnessctl", "--class=backlight", "s", `${Math.max(root.backlightBrightness, 1)}%`];
        backlightUpdateProc.running = true;

        backlightNeedUpdate = false;
        return;
      }

      for (let i = 0; i < needUpdate.length; ++i) {
        if (!needUpdate[i])
          continue;

        ddcUpdateProc.command = ["ddcutil", "setvcp", "10", "" + parseInt(Math.round(brightnesses[i])), "--bus", monitorsDdcBuses[i]];
        ddcUpdateProc.running = true;
        needUpdate[i] = false;

        return;
      }

      updateTimer.running = false;
    }
  }

  Timer {
    id: ddcVcpNextTimer
    interval: 1
    repeat: false
    running: false

    onTriggered: () => {
      ddcVcpProc.running = true;
    }
  }

  function gatherBegin() {
    for (let i = 0; i < monitors.length; ++i) {
      brightnesses[i] = -1;
      needUpdate[i] = false;
    }

    cyclingDdcIndex = 0;

    for (let i = 0; i < monitorsDdcBuses.length; ++i) {
      if (monitorsDdcBuses[i] < 0)
        continue;
      ddcVcpProc.command = ["ddcutil", "getvcp", "10", "--bus", "" + monitorsDdcBuses[i], "--brief"];
      ddcVcpProc.running = true;
      break;
    }
  }

  Timer {
    id: gatherTimer
    interval: 100
    running: false

    onTriggered: () => {
      gatherBegin();
    }
  }

  Process {
    command: ["ddcutil", "detect", "--brief"]
    running: true

    stdout: SplitParser {
      splitMarker: "Display "
      onRead: data => {
        if (data == "")
          return;

        if (data.indexOf("Invalid display") != -1)
          return; // skip this: invalid control

        // cleanup: this happens due to reloads
        if (monitorsDdcBuses.length >= monitors.length) {
          monitorsDdcBuses = [];
          for (let i = 0; i < monitors.length; ++i) {
            monitorsDdcBuses[i] = -1;
          }
        }

        // find the monitor
        for (let i = 0; i < monitors.length; ++i) {
          if (data.indexOf("-" + monitors[i]) != -1) {
            let b = data.indexOf("i2c-") + 4;
            let e = data.indexOf("\n", b);
            monitorsDdcBuses[i] = parseInt(data.substr(b, e - b));
            break;
          }
        }

        gatherTimer.restart();
      }
    }
  }

  IpcHandler {
    target: "brightness"

    // FIXME: implement getActiveBrightness or somehow use the service more properly

    function increment() {
      if (C.Config.misc.brightnessSplit)
        root.incrementActive(5);
      else
        root.setOverall(Math.min(100, root.overallBrightness + 5));
    }

    function decrement() {
      if (C.Config.misc.brightnessSplit)
        root.incrementActive(-5);
      else
        root.setOverall(Math.max(1, root.overallBrightness - 5));
    }
  }
}
