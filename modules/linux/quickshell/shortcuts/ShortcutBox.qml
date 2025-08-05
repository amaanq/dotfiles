import "../config" as C
import "../commonwidgets" as CW

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
  id: root
  property real padding: 3
  property alias uniformCellSizes: layout.uniformCellSizes
  property string shortcut: "SUPER+XD"
  property string description: "Does a funny"
  Layout.fillWidth: true
  implicitHeight: layout.implicitHeight + padding * 2
  color: "transparent"
  radius: 4

  RowLayout {
    id: layout
    anchors {
      fill: parent
      margins: root.padding
    }

    spacing: 6

    CW.StyledText {
      text: root.shortcut
      Layout.alignment: Qt.AlignTop
      horizontalAlignment: Text.AlignLeft
      color: C.Config.theme.primary
      Layout.preferredWidth: 180
      wrapMode: Text.Wrap
    }

    CW.StyledText {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignTop
      text: root.description
      horizontalAlignment: Text.AlignLeft
      wrapMode: Text.Wrap
    }
  }
}
