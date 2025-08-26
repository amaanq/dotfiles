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

  property string label: "Vaxry was here"
  property alias value: s.value
  property alias from: s.from
  property alias to: s.to
  property bool floatVal: false
  signal moved

  CW.StyledText {
    text: label
  }

  Item {
    Layout.fillWidth: true
  }

  CW.StyledSlider {
    id: s

    from: 0
    to: 100
    value: 50
    onMoved: root.moved()
    snapMode: Slider.SnapOnRelease
    stepSize: root.floatVal ? 0.01 : 1
  }

  CW.StyledText {
    Layout.fillHeight: true
    Layout.preferredWidth: 20
    text: root.floatVal ? "" + (Math.round(s.value * 10.0) / 10.0) : "" + Math.round(s.value)
    horizontalAlignment: Text.AlignRight
  }
}
