import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
  id: root

  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: WlrLayer.overlay
  anchors: C.Config.noAnchors
  color: "transparent"
  visible: S.UpdateState.versionMismatch
  implicitWidth: 600
  implicitHeight: 120

  HyprlandFocusGrab {
    id: grab

    active: S.UpdateState.versionMismatchOpen
    windows: [root]
    onCleared: () => {
      S.UpdateState.versionMismatch = false;
      S.UpdateState.versionMismatchOpen = false;
    }
  }

  Rectangle {
    id: rectt

    focus: S.UpdateState.versionMismatch
    Keys.onPressed: event => {
      // Esc to close
      if (event.key === Qt.Key_Escape)
        S.UpdateState.versionMismatch = false;
    }
    radius: 10
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? 1 : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)
    anchors.fill: parent
    visible: opacity != 0
    opacity: S.UpdateState.versionMismatch ? 1 : 0

    anchors {
      horizontalCenter: parent.horizontalCenter
      verticalCenter: parent.verticalCenter
    }

    ColumnLayout {
      id: layout

      spacing: 10

      anchors {
        fill: parent
        margins: 20
      }

      anchors {
        left: parent.left
        top: parent.top
        right: parent.right
      }

      CW.StyledText {
        Layout.fillWidth: true
        text: "Version mismatch"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h2
        color: C.Config.theme.primary
      }

      CW.HorizontalLine {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: false
        implicitWidth: 100
      }

      CW.StyledText {
        Layout.fillWidth: true
        text: "The Hyprland Desktop Experience needs to be updated to match the Hyprland version.\nPlease update by going to the right panel -> updates."
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.normal
        color: C.Config.theme.primary
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }
}
