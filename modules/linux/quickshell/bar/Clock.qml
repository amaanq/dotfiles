import QtQuick
import Quickshell

import "../commonwidgets" as CW
import "../config" as C

CW.StyledText {
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  text: C.Config.formatDateTime(clock.date)
}
