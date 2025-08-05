import QtQuick
import "../config" as C
import "../state" as S

Text {
  id: root
  property real fill: 0
  property real iconSize: 18
  color: C.Config.theme.on_surface
  font {
    family: "Material Symbols Outlined"
    pixelSize: root.iconSize
    variableAxes: {
      "FILL": root.fill,
      "opsz": root.iconSize
    }
  }
}
