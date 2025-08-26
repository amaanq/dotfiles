pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQml.Models
import Quickshell.Services.Notifications
import qs.notifs

Singleton {
  id: root

  property var trackedNotifs: []
  property var overlayNotifs: trackedNotifs.filter(n => n.showInOverlay)
  property bool notifOverlayOpen: overlayNotifs.length != 0
  property var defaultNotifTimeout: 5000
  property int pauseRefs: 0
  property bool dndEnabled: false

  IpcHandler {
    target: "notification"

    function clear() {
      root.trackedNotifs = [];
    }

    function closeLast() {
      root.trackedNotifs = root.trackedNotifs.slice(1);
    }
  }

  Component {
    id: notifComponent

    TrackedNotification {
      defaultTimeout: root.defaultNotifTimeout
      paused: root.pauseRefs != 0
      onRemoved: {
        root.trackedNotifs = root.trackedNotifs.filter(n => n != this);
        destroy();
      }
    }
  }

  NotificationServer {
    id: notifServer
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    actionsSupported: true
    actionIconsSupported: true
    imageSupported: true

    onNotification: notif => {
      notif.tracked = true;

      const newNotif = notifComponent.createObject(root, {
        notif
      });

      root.trackedNotifs = [newNotif, ...root.trackedNotifs];
    }
  }
}
