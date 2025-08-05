import QtQuick
import QtQuick.Layouts
import "../config" as C
import "../commonwidgets" as CW

CW.CutRectangle {
  id: root
  property alias size: root.implicitWidth

  size: 8

  color: C.Config.theme.outline
  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
  implicitHeight: size
  radius: size / 2
}
