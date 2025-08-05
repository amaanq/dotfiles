pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property bool shortcutsOpen: false
  property bool shortcutsOpenGrab: false
}
