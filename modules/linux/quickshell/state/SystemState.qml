pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string host
  property string uptime
  property string username
  property real ram
  property real cpu
  property string networkD
  property string networkU
  property string temp
  property string osString

  function setHypridleStatus(enable) {
    if (enable)
      Quickshell.execDetached(["hypridle"])
    else
      Quickshell.execDetached(["bash", "-c", "killall -9 hypridle"]);
  }

  function netSpeedToInt(input) {
    let bytes = 0;
    if (input[input.length - 1] == 'K')
      bytes = parseInt(input.substr(0, input.length - 1)) * 1000;
    else if (input[input.length - 1] == 'M')
      bytes = parseInt(input.substr(0, input.length - 1)) * 1e+06;
    else
      bytes = parseInt(input);
    return bytes;
  }

  function netSpeedToString(bytes) {
    let str = "";
    if (bytes > 1e+06)
      str = (parseInt(bytes / 100000) / 10) + "M";
    else if (bytes > 1000)
      str = (parseInt(bytes / 100) / 10) + "K";
    else
      str = (bytes) + "B";
    return str;
  }

  Process {
    command: ["cat", "/etc/hostname"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return host = data;
      }
    }
  }

  Process {
    command: ["whoami"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return username = data;
      }
    }
  }

  Process {
    command: ["cat", "/etc/os-release"]
    running: true

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const lines = data.split("\n");
        for (let l of lines) {
          if (l.indexOf("NAME") == -1)
            continue;

          const first = l.indexOf("\"");
          osString = l.substr(first + 1, l.indexOf("\"", first + 1) - first - 1);

          break;
        }
      }
    }
  }

  Process {
    id: uptimeProc

    command: ["uptime", "-p"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return uptime = data;
      }
    }
  }

  Process {
    id: cpuProc

    command: ["bash", "-c", "top -bn1 | grep '%Cpu' | tail -1 | awk '{print 100-$8}'"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return cpu = Math.round(parseInt(data));
      }
    }
  }

  Process {
    id: ramProc

    command: ["bash", "-c", "free | grep Mem | awk '{print int($3/$2 * 100.0)}'"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return ram = data;
      }
    }
  }

  Process {
    id: networkProc

    command: ["bash", "-c", "ifstat -t 1"]
    running: true

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        let speedstrs = data.split('\n');
        // drop the first three as they are labels
        speedstrs = speedstrs.slice(3);
        let up = 0;
        let down = 0;
        for (let line of speedstrs) {
          let split = line.split(' ').filter(i => {
            return i;
          });
          if (!isNaN(split[0]))
            continue;

          if (split[5] == undefined)
            continue;

          down += netSpeedToInt(split[5]);
          up += netSpeedToInt(split[7]);
        }
        networkD = `${netSpeedToString(down)}`;
        networkU = `${netSpeedToString(up)}`;
        return true;
      }
    }
  }

  Process {
    id: tempProc

    command: ["bash", "-c", "sensors | grep -E '(^Tctl)|(^Core [0-9]+:)' | sed -s -E 's/Core\ [0-9]+:/temp:/g' | awk '{gsub(/[+°C]/,\"\"); print $2}' | sort -nr | head -n 1"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        return temp = Math.round(parseInt(data));
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: () => {
      ramProc.running = true;
      cpuProc.running = true;
      networkProc.running = true;
      tempProc.running = true;
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: () => {
      uptimeProc.running = true;
    }
  }
}
