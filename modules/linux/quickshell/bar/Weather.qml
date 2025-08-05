import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config" as C
import "../state" as S
import "../commonwidgets" as CW

RowLayout {
  id: root
  spacing: 3

  CW.FontIcon {
    text: S.WeatherState.icon
    font.pointSize: C.Config.fontSize.small
  }

  CW.StyledText {
    text: S.WeatherState.temp + ", " + S.WeatherState.location
    color: C.Config.theme.on_surface
  }
}
