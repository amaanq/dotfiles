import "../../commonwidgets" as CW
import "../../config" as C
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

Item {
  id: root

  property string label: "Vax was here"
  property string icon: "brightness_5"
  property alias value: s.value
  signal moved

  implicitHeight: 40

  ColumnLayout {
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 4
    }

    RowLayout {
      Layout.fillWidth: true
      z: 1

      CW.StyledText {
        text: label
      }

      Item {
        Layout.fillWidth: true
      }

      CW.StyledText {
        text: Math.round(value) + "%"
        horizontalAlignment: Text.AlignRight
      }

      CW.FontIcon {
        text: root.icon
        font.pointSize: C.Config.fontSize.large
      }
    }

    CW.StyledSlider {
      id: s

      Layout.fillWidth: true
      z: 2
      Layout.topMargin: -5

      topPadding: 4
      bottomPadding: 4
      from: 0
      to: 100
      value: 50

      onMoved: root.moved()
    }
  }
}
