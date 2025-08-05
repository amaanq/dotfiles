//@ pragma UseQApplication
//@ pragma IgnoreSystemSettings
//@ pragma DataDir $BASE/quickshell/hyprland-shell
//@ pragma StateDir $BASE/quickshell/hyprland-shell
import "./config" as C
import "./shortcuts" as SH
import "./versionMismatch" as V
import "./state" as S
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "config"

Scope {
  property bool showBars: true

  Component.onCompleted: {
    console.log("Shell initialized");
    S.BrightnessState.load();
  }

  Variants {
    model: {
      S.UpdateState.init();

      let mons = Quickshell.screens.filter(m => {
        if (Config.settings.panels.monitorChoiceMode == 0)
          return !Config.settings.panels.excludedMonitors.includes(m.name);
        else
          return (Config.settings.panels.includedMonitors.includes(m.name) || Config.settings.panels.includedMonitors.includes("" + Quickshell.screens.indexOf(m)));
      });

      if (mons.length == 0) {
        S.ErrorState.monitorError = true;
        return [Quickshell.screens[0]]; // prevent a softlock
      }
      S.ErrorState.monitorError = false;
      return mons;
    }

    ScreenState {
      required property ShellScreen modelData

      screen: modelData
      showBar: showBars
    }
  }

  SH.ShortcutsPanel {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  }


  V.VersionMismatch {
    screen: Quickshell.screens[0]
  }

  IpcHandler {
    target: "update"

    function updated(epoch: int): void {
      S.UpdateState.setUpdated(epoch);
    }
  }

  IpcHandler {
    target: "bar"

    function setVisible(visible: int): void {
      showBars = !!visible
    }

    function toggleVisible(): void {
      showBars = !showBars
    }
  }
}
