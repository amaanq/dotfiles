pragma ComponentBehavior: Bound

import qs.config as C
import qs.state as S
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick // for Text
import QtQuick.Layouts
import QtQuick.Layouts
import Quickshell // for ShellRoot and PanelWindow
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

WlrLayershell {
  id: root

  // wrapper height check avoids qt crashes
  visible: wrapper.implicitHeight != 0 || S.NotificationState.notifOverlayOpen
  color: "transparent"
  namespace: "hyprland-shell:notifs"
  layer: WlrLayer.Top
  implicitWidth: notifWidth + rightMargin
  exclusiveZone: 0

  property real notifWidth: 360
  property real rightMargin: C.Config.settings.bar.horizontalGap

  anchors {
    right: true
    top: true
    bottom: true
  }

  mask: Region {
    item: wrapper
  }

  Item {
    id: wrapper
    implicitWidth: root.width
    implicitHeight: Math.min(list.contentHeight, root.height)

    HoverHandler {
      onHoveredChanged: {
        S.NotificationState.pauseRefs += (hovered ? 1 : -1);
      }
    }

    ListView {
      id: list
      implicitWidth: root.width
      implicitHeight: root.height
      topMargin: 5

      model: ScriptModel {
        values: S.NotificationState.overlayNotifs
      }

      delegate: NotificationBox {
        required property TrackedNotification modelData
        trackedNotif: modelData
        entryFactor: trackedNotif.overlayEntryFactor
        contentWidth: root.notifWidth
        rightMargin: root.rightMargin
      }
    }
  }
}
