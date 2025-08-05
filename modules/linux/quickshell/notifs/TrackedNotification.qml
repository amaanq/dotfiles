import qs.config as C
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../state" as S

Scope {
  id: root
  required property Notification notif
  property int defaultTimeout: 5000
  property bool paused: false
  signal removed

  property bool showInOverlay: !S.NotificationState.dndEnabled
  property int expireTimeout: notif.expireTimeout

  property real timePercentage
  NumberAnimation on timePercentage {
    running: true
    duration: root.expireTimeout === -1 ? root.defaultTimeout : root.expireTimeout
    paused: running && root.paused
    from: 1
    to: 0
    onFinished: root.hide()
  }

  component EntryAnim: NumberAnimation {
    running: true
    duration: C.Globals.anim_SLOW
    easing.type: Easing.BezierSpline
    easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    to: 1

    function hide() {
      to = 0;
      restart();
    }
  }

  property real overlayEntryFactor: 0
  EntryAnim on overlayEntryFactor {
    id: overlayEntryAnim
    onFinished: if (to === 0)
      root.showInOverlay = false
  }

  property real entryFactor: 0
  EntryAnim on entryFactor {
    id: entryAnim
    onFinished: if (to === 0)
      root.removed()
  }

  function hide(): void {
    overlayEntryAnim.hide();
  }

  function dismiss(): void {
    notif.dismiss();
  }

  RetainableLock {
    id: notifLock
    object: root.notif
    locked: true
    onDropped: {
      overlayEntryAnim.hide();
      entryAnim.hide();
    }
  }
}
