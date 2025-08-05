import QtQuick
import Quickshell

Scope {
  id: root

  PersistentProperties {
    id: props
    property bool show: false
  }

  property alias show: props.show
  readonly property bool visible: loader.item?.targetVisible ?? false
  required property Component delegate

  onShowChanged: {
    if (loader.item)
      loader.item.containerShow = show;
    else
      loader.activeAsync = show;
  }

  LazyLoader {
    id: loader
    component: root.delegate
  }

  Connections {
    target: loader.item

    function onFinished() {
      loader.activeAsync = false;
    }

    function onClosed() {
      root.show = false;
    }
  }
}
