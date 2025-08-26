import QtQuick
import QtQuick.Layouts
import Quickshell

import "../commonwidgets" as CW
import "../config" as C
import "../state" as S

RowLayout {
  CW.FontIcon {
    text: "keyboard"
  }

  CW.StyledText {
    text: S.MiscState.keyboardLayout
  }
}
