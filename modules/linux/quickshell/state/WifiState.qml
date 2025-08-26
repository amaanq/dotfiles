pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property bool wifiEnabled: false

  // ssid, security, active, bars
  property var wifiStations: []
  property string lastWifiScanResult: ""

  property var pendingNmcliCommands: []
  property bool pendingNmcliScan: false

  property bool wifiScanning: false

  function disconnect(ssid) {
    // FIXME: this will break with named stations I think...
    pendingNmcliCommands = [["nmcli", "c", "down", ssid], ...pendingNmcliCommands];
  }

  function connect(ssid) {
    pendingNmcliCommands = [["nmcli", "--ask", "device", "wifi", "connect", ssid], ...pendingNmcliCommands];
  }

  function setWifiEnabled(on) {
    if (on == wifiEnabled)
      return;

    wifiEnabled = on;
    pendingNmcliCommands = [["nmcli", "radio", "wifi", on ? "on" : "off"], ...pendingNmcliCommands];
    pendingNmcliScan = true;

    wifiStations = [];
  }

  function refreshWifi() {
    if (nmcliListProc.running)
      return;

    if (!wifiEnabled) {
      wifiStations = [];
      return;
    }

    nmcliListProc.running = true;
    wifiScanning = true;
  }

  function splitEscaped(str, sep = ':', esc = '\\') {
    const out = [];
    let current = '';
    let escaped = false;

    for (const ch of str) {
      if (escaped) {
        current += ch;
        escaped = false;
      } else if (ch == esc)
        escaped = true;
      else if (ch == sep) {
        out.push(current);
        current = '';
      } else
        current += ch;
    }
    out.push(current);
    return out;
  }

  function stationFromSSID(ssid) {
    for (let st of wifiStations) {
      if (st.ssid == ssid)
        return st;
    }
    return null;
  }

  Process {
    id: updateNmcliProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        ; // doesn't get called most of the time due to no stdout
      }
    }
  }

  Process {
    id: nmcliListProc
    running: false

    command: ["nmcli", "--terse", "-f", "IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY,FREQ", "dev", "wifi", "list"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {

        wifiScanning = false;

        // FIXME: this will still change quite often due to signal. Maybe only compare the things we get.
        if (lastWifiScanResult == data)
          return;

        lastWifiScanResult = data;

        const lines = data.split("\n");
        wifiStations = [];
        let activeStation = null;
        for (let line of lines) {
          const lineParsed = splitEscaped(line);

          if (lineParsed.length < 8)
            continue;
          if (lineParsed[0].indexOf("IN-USE") != -1)
            continue;

          let s = {};

          // console.log(lineParsed)

          s.active = lineParsed[0] == "*";
          s.ssid = lineParsed[2];
          s.security = lineParsed[8];
          s.bars = 4 - (lineParsed[7].match(/\_/g) || []).length;
          s.bssid = lineParsed[1];
          s.points = 1;
          s.freq = Math.round(parseInt(lineParsed[9].substr(0, lineParsed[9].length - 3)) / 100.0) / 10.0

          if (s.ssid == "")
            continue; // hidden station

          if (stationFromSSID(s.ssid) != null) {
            for (let i = 0; i < wifiStations.length; ++i) {
              if (wifiStations[i].ssid == s.ssid) {
                wifiStations[i].points++;
                wifiStations[i].active = wifiStations[i].active || s.active;
                wifiStations[i].bars = Math.max(wifiStations[i].bars, s.bars);
                wifiStations[i].freq = Math.max(wifiStations[i].freq, s.freq);
                break;
              }
            }
            continue;
          }

          wifiStations = [s, ...wifiStations];
        }

        for (let i = 0; i < wifiStations.length; ++i) {
          if (wifiStations[i].active) {
            activeStation = wifiStations[i];
            wifiStations.splice(i, 1);
            break;
          }
        }

        if (activeStation != null)
          wifiStations = [...wifiStations, activeStation];
        wifiStations = wifiStations.reverse();
      }
    }
  }

  Timer {
    id: nmcliListTimer
    running: wifiEnabled
    onTriggered: {
      if (!nmcliListProc.running)
        nmcliListProc.running = true;
    }
  }

  Timer {
    id: updateNmcliTimer
    repeat: true
    running: pendingNmcliCommands.length > 0
    interval: 100

    onTriggered: {
      if (updateNmcliProc.running)
        return;

      updateNmcliProc.command = pendingNmcliCommands[0];
      updateNmcliProc.running = true;

      pendingNmcliCommands = pendingNmcliCommands.slice(1);

      if (pendingNmcliCommands.length == 0 && pendingNmcliScan) {
        pendingNmcliScan = false;
        refreshWifi();
      }
    }
  }

  Process {
    id: checkWifiEnabledState
    running: true
    command: ["nmcli", "radio", "wifi"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        wifiEnabled = data.indexOf("enabled") != -1;
      }
    }
  }
}
