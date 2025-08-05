pragma Singleton
import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import "../state" as S

Singleton {
  property var anim_CURVE_SMOOTH_SLIDE: [0.23, 1, 0.32, 1, 1, 1]
  property var anim_CURVE_ALMOST_LINEAR: [0.5, 0.5, 0.75, 1, 1, 1]

  property var anim_FAST: 130
  property var anim_MEDIUM: 240
  property var anim_SLOW: 400

  property bool isFedora: S.SystemState.osString == "Fedora Linux" || S.SystemState.osString == "Nobara Linux"
}
