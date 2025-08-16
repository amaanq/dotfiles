import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../config" as C

BasePopupDelegate {
  id: root
  default property alias data: content.data

  required property Item owner

  property point ownerPosition

  Component.onCompleted: {
    ownerPosition = owner.QsWindow.window.contentItem.mapFromItem(owner, owner.width / 2, owner.height / 2);

    revealProgress = Qt.binding(() => ready && root.targetVisible ? 1 : 0);
  }

  readonly property real raiseDist: 10
  readonly property real margin: 5

  property real windowX: Math.max(4, root.ownerPosition.x - window.width / 2)
  property real maxContentWidth: 0
  property real maxContentHeight: 0

  hoverHandler: hoverHandler

  PopupWindow {
    id: window
    visible: root.ready
    // color: "#30ffffff"
    color: "transparent"

    property bool inhibitGrab: false

    anchor {
      window: owner?.QsWindow.window ?? null
      adjustment: PopupAdjustment.None
      gravity: C.Config.settings.bar.edge == "bottom" ? (Edges.Top | Edges.Right) : (Edges.Bottom | Edges.Right)
      rect.y: C.Config.settings.bar.edge == "bottom" ? 0 : anchor.window.exclusiveZone - root.raiseDist - C.Config.settings.bar.verticalGap
      rect.x: root.windowX
    }

    implicitWidth: root.maxContentWidth || content.implicitWidth
    implicitHeight: root.maxContentHeight || content.implicitHeight + root.raiseDist + root.margin

    HyprlandWindow.opacity: root.revealProgress

    HyprlandFocusGrab {
      active: root.grab && root.targetVisible && !window.inhibitGrab
      windows: [window]
      onCleared: root.closed()
    }

    WrapperRectangle {
      id: content

      margin: 15
      radius: C.Config.settings.panels.radius
      color: C.Config.applyBaseOpacity(C.Config.theme.background)
      border.width: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
      border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)

      y: C.Config.settings.bar.edge == "bottom" ? (window.implicitHeight - content.implicitHeight + ((1.0 - root.revealProgress) * root.raiseDist) - C.Config.settings.bar.verticalGap) : (root.revealProgress * root.raiseDist + root.raiseDist)
    }

    mask: Region {
      item: root.hoverable && root.targetVisible && root.revealProgress > 0.1 ? content : null
    }

    HoverHandler {
      id: hoverHandler
    }
  }
}
