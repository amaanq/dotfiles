import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config" as C

BasePopupDelegate {
  id: root
  default property alias data: content.data
  property alias anchors: window.anchors
  property bool clip: false

  Component.onCompleted: {
    revealProgress = Qt.binding(() => ready && root.targetVisible ? 1 : 0);
  }

  hoverHandler: hoverHandler

  required property var bar

  PanelWindow {
    id: window
    visible: root.ready
    anchors {
      top: true
      bottom: true
    }
    screen: bar.screen
    exclusiveZone: 0
    WlrLayershell.namespace: "hyprland-shell:bar"
    focusable: false
    //color: "#30ffffff"
    color: "transparent"

    property bool inhibitGrab: false

    implicitWidth: content.implicitWidth + (root.bar.uncompactState * root.bar.gapsHorz)
    implicitHeight: content.implicitHeight

    HyprlandWindow.opacity: root.revealProgress

    HyprlandFocusGrab {
      active: root.grab && root.targetVisible && !window.inhibitGrab
      windows: [window]
      onCleared: root.closed()
    }

    WrapperRectangle {
      id: content
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.margins: root.bar.uncompactState * root.bar.gapsVert ?? 100
      margin: 15
      clip: root.clip
      radius: root.bar.uncompactState * C.Config.settings.panels.radius
      color: C.Config.applyBaseOpacity(C.Config.theme.background)
      border.width: root.bar.uncompactState * root.bar.borderMargin
      border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)

      x: width * ((1 - root.revealProgress * 0.5) - 0.5)
    }

    mask: Region {
      item: root.hoverable && root.targetVisible && root.revealProgress > 0.1 ? content : null
    }

    HoverHandler {
      id: hoverHandler
    }
  }
}
