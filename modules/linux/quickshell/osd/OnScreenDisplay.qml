import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../config" as C
import "../commonwidgets" as CW
import "../state" as S

PanelWindow {
  id: root

  property real osdGap: 8
  property bool showBrightness: false // true = brightness, false = volume

  visible: false
  color: "transparent"
  WlrLayershell.namespace: "hyprland-shell:osd"
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.layer: WlrLayer.Overlay

  anchors {
    top: (C.Config.edge == C.Config.BarEdge.Top)
    bottom: !(C.Config.edge == C.Config.BarEdge.Top)
  }

  Timer {
    id: osdTimeout
    interval: C.Config.settings.osd.timeoutDuration
    onTriggered: {
      root.visible = false;
    }
  }

  function triggerShow(showBrightness) {
    root.showBrightness = showBrightness;
    root.visible = true;
    osdTimeout.restart();
  }

  implicitWidth: background.implicitWidth
  implicitHeight: background.implicitHeight + root.osdGap

  Connections {
    // Listen to volume changes
    target: S.PipewireState.defaultSink?.audio ?? null
    function onVolumeChanged() {
      if (!S.PipewireState.defaultSink?.ready ?? false)
        return;
      root.triggerShow(false);
    }
    function onMutedChanged() {
      if (!S.PipewireState.defaultSink?.ready ?? false)
        return;
      root.triggerShow(false);
    }
  }

  Connections {
    // Listen to brightness changes
    target: S.BrightnessState
    function onNeedUpdateChanged() {
      root.triggerShow(true);
    }
    function onBacklightNeedUpdateChanged() {
      root.triggerShow(true);
    }
  }

  WrapperRectangle { // Background
    id: background
    anchors {
      fill: parent
      topMargin: C.Config.edge == C.Config.BarEdge.Top ? root.osdGap : 0
      bottomMargin: C.Config.edge == C.Config.BarEdge.Top ? 0 : root.osdGap
    }
    topMargin: 4
    bottomMargin: 4
    leftMargin: 12
    rightMargin: 12
    radius: C.Config.settings.panels.radius
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)

    Loader {
      id: osdLoader
      // sourceComponent: root.showBrightness ? brightnessOsd : volumeOsd
      Connections {
        target: root
        function onShowBrightnessChanged() {
          switchAnim.complete();
          switchAnim.start();
        }
      }

      SequentialAnimation {
        id: switchAnim

        NumberAnimation {
          target: osdLoader
          properties: "opacity"
          from: 1
          to: 0
          duration: 100
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_EMPHASIZED_FIRST_HALF
        }
        PropertyAction {
          target: osdLoader
          property: "sourceComponent"
          value: root.showBrightness ? brightnessOsd : volumeOsd
        }
        NumberAnimation {
          target: osdLoader
          properties: "opacity"
          from: 0
          to: 1
          duration: 100
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_EMPHASIZED_LAST_HALF
        }
      }
    }

    Component {
      id: brightnessOsd
      OsdValue {
        icon: "brightness_6" // FIXME: dynamic icon based on brightness level
        value: C.Config.settings.misc.brightnessSplit ? (S.BrightnessState.brightnesses[root.screen.name] / 100) : (S.BrightnessState.overallBrightness / 100)
        displayText: Math.round(value * 100)
      }
    }
    Component {
      id: volumeOsd
      OsdValue {
        icon: S.PipewireState.defaultSink?.audio?.muted ? "volume_off" : (S.PipewireState.defaultSink?.audio?.volume ?? 0) > 0.5 ? "volume_up" : (S.PipewireState.defaultSink?.audio?.volume ?? 0) > 0 ? "volume_down" : "volume_mute"
        value: S.PipewireState.defaultSink?.audio?.volume ?? 0
        displayText: Math.round((S.PipewireState.defaultSink?.audio?.volume ?? 0) * 100)
      }
    }
  }
}
