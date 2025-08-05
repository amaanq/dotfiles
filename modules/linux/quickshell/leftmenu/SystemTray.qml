import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Qt5Compat.GraphicalEffects
import "../config" as C

WrapperRectangle {
  id: root
  resizeChild: false
  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  margin: 5
  radius: 5
  opacity: SystemTray.items.values.length > 0 ? 1 : 0
  visible: opacity > 0
  Behavior on opacity {
    NumberAnimation {
      duration: C.Globals.anim_FAST
      easing.type: Easing.Linear
    }
  }

  RowLayout {
    Repeater {
      model: SystemTray.items

      WrapperMouseArea {
        id: delegate
        required property SystemTrayItem modelData

        Item {
          implicitWidth: trayIcon.implicitWidth
          implicitHeight: trayIcon.implicitHeight

          IconImage {
            id: trayIcon
            source: delegate.modelData.icon
            implicitSize: 16
            visible: !C.Config.settings.tray.monochromeIcons
          }

          Loader {
            active: C.Config.settings.tray.monochromeIcons
            anchors.fill: trayIcon
            sourceComponent: Item {
              Desaturate {
                id: desaturatedIcon
                visible: false // There's already color overlay
                anchors.fill: parent
                source: trayIcon
                desaturation: 1 // 1.0 means fully grayscale
              }
              ColorOverlay {
                anchors.fill: desaturatedIcon
                source: desaturatedIcon
                color: C.Config.theme.on_surface
              }
            }
          }
        }

        acceptedButtons: Qt.RightButton | Qt.LeftButton

        onClicked: event => {
          switch (event.button) {
          case Qt.LeftButton:
            modelData.activate();
            break;
          case Qt.RightButton:
            if (modelData.hasMenu)
              menu.open();
            break;
          }
          event.accepted = true;
        }

        QsMenuAnchor {
          id: menu
          menu: delegate.modelData.menu
          onVisibleChanged: QsWindow.window.inhibitGrab = visible

          anchor {
            item: trayIcon
            edges: Edges.Left | Edges.Bottom
            gravity: Edges.Right | Edges.Bottom
            adjustment: PopupAdjustment.FlipX
          }
        }
      }
    }
  }
}
