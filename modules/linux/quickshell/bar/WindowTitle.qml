import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../commonwidgets" as CW

CW.StyledText {
  required property var panelWindow
  readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor

  text: ToplevelManager.activeToplevel?.activated ? ToplevelManager.activeToplevel.title : `Workspace ${monitor?.activeWorkspace?.id}`

  horizontalAlignment: Text.AlignHCenter
  elide: Text.ElideRight
}
