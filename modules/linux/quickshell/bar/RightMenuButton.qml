import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../popup" as P
import "../rightmenu" as M
import "../commonwidgets" as CW

BarButton {
  id: root

  WrapperItem {
    resizeChild: false
    implicitWidth: height
    CW.FontIcon {
      text: "menu"
    }
  }

  function togglePopup() {
    pop.show = !pop.show;
  }

  onClicked: root.togglePopup()

  P.PopupHandle {
    id: pop
    reloadableId: "rightMenuHandle"

    delegate: P.LayerPopupDelegate {
      hoverable: true
      grab: true
      anchors.right: true
      bar: root.QsWindow.window
      clip: true

      M.RightMenu {}
    }
  }

  // FIXME: fox why does closing only work after we wiggle the mouse
  GlobalShortcut {
    name: "rightMenuToggle"
    appid: "hyprland-shell"
    description: qsTr("Toggles right menu on press")

    onPressed: root.togglePopup()
  }
}
