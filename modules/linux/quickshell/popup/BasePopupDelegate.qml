import QtQuick
import Quickshell
import "../config" as C

Scope {
  property bool hoverable: false
  property bool ready: true
  property bool grab: false

  property bool containerShow: true
  property HoverHandler hoverHandler
  readonly property bool targetVisible: containerShow || (hoverable && hoverHandler.hovered)
  signal finished
  signal closed

  onTargetVisibleChanged: if (revealProgress == 0)
    finished()

  function close() {
    if (revealProgress == 0)
      finished();
    else
      revealProgress = 0;
  }

  property real revealProgress: 0
  Behavior on revealProgress {
    NumberAnimation {
      duration: 400
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }

  onRevealProgressChanged: {
    if (revealProgress == 0)
      finished();
  }
}
