import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar" as B
import "config" as C
import "keybinds" as K
import "notifs" as N
import "osd" as O
import "monitorRounding" as MR

Scope {
    id: root

    property ShellScreen screen
    property bool hasFullscreenWindow: C.Config.settings.panels.compactEnabled && Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen
    property bool showBar: true

    B.Bar {
        screen: root.screen
        compact: root.hasFullscreenWindow
        show: showBar
    }

    MR.RoundedMonitorElement {
        screen: root.screen
        show: C.Config.settings.monitorRounding.enabled && !C.Config.settings.monitorRounding.allMonitors
    }

    N.NotificationPanel {
        screen: root.screen
    }

    O.OnScreenDisplay {
        screen: root.screen
    }
}
