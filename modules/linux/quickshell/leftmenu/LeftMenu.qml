import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

WrapperItem {
  implicitWidth: 400
  implicitHeight: leftMenuLayout.implicitHeight

  ColumnLayout {
    id: leftMenuLayout
    spacing: 15
    InfoCard {
      Layout.fillWidth: true
    }
    Mpris {
      Layout.fillWidth: true
    }
    SettingsSlice {
      Layout.fillWidth: true
    }
    SystemTray {
      Layout.fillWidth: true
    }
  }
}
