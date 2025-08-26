import "../../../bar" as B
import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RowLayout {
  id: root

  property string label: "end was here"
  property alias value: s.value
  property alias from: s.from
  property alias to: s.to
  property alias stepSize: s.stepSize
  property bool floatVal: false
  signal moved

  CW.StyledText {
    text: label
  }

  Item {
    Layout.fillWidth: true
  }

  CW.StyledSpinBox {
    id: s

    from: 0
    to: 100
    stepSize: root.floatVal ? 0.5 : 1
    onValueModified: root.moved()
  }
}
