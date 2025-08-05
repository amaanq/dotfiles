import "../bar" as B
import "../config" as C
import "../commonwidgets" as CW
import "../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  property alias label: mt.text
  property alias bold: mt.font.bold
  property string sublabel: ""
  property alias checked: sw.checked
  signal toggled

  onClicked: {
    sw.checked = !sw.checked;
    root.toggled();
  }

  RowLayout {
    ColumnLayout {
      spacing: 2
      CW.StyledText {
        id: mt
        text: "Vaxry was here"
      }
      CW.StyledText {
        text: "<i>" + sublabel + "</i>"
        visible: sublabel != ""
        opacity: 0.8
        font.pointSize: mt.font.pointSize * 0.7
      }
    }

    Item {
      Layout.fillWidth: true
    }

    CW.StyledSwitch {
      id: sw
      onToggled: root.toggled()
    }
  }
}
