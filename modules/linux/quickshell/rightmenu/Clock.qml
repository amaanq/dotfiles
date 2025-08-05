import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config" as C
import "../bar" as B
import "../state" as S

ColumnLayout {
  id: root

  property var time: C.Config.formatDateTimeSplit(clock.date)

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Text {
    text: time[1]

    Layout.fillWidth: true

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 17
    color: C.Config.theme.on_surface
  }

  Text {
    text: time[0]

    Layout.fillWidth: true

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 10
    color: C.Config.theme.on_surface
  }
}
