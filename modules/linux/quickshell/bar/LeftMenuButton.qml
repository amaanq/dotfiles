import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../popup" as P
import "../state" as S
import "../leftmenu" as M
import "../commonwidgets" as CW

BarButton {
  id: root

  WrapperItem {
    resizeChild: false
    implicitWidth: height
    CW.FontIcon {
      text: "home"
    }
  }

  function togglePopup() {
    pop.show = !pop.show;

    if (pop.show)
      S.WifiState.refreshWifi();
  }

  onClicked: root.togglePopup()

  P.PopupHandle {
    id: pop
    reloadableId: "leftMenuHandle"

    delegate: P.PopupDelegate {
      owner: root
      hoverable: true
      grab: true
      windowX: root.QsWindow.window.uncompactState * root.QsWindow.window.gapsHorz
      maxContentHeight: 750 // arbitrarily determined for now

      M.LeftMenu {}
    }
  }

  GlobalShortcut {
    name: "leftMenuToggle"
    appid: "hyprland-shell"
    description: qsTr("Toggles left menu on press")

    onPressed: root.togglePopup()
  }
}
