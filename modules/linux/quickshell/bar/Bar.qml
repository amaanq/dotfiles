import "../config" as C
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: root

  property bool compact: false
  property bool show: true
  property real barRadius: C.Config.settings.panels.radius
  property real barHeight: C.Config.settings.bar.height
  property real gapsHorz: C.Config.settings.bar.horizontalGap
  property real gapsVert: C.Config.settings.bar.verticalGap
  property real innerPadHorz: 8
  property real compactHeight: barHeight
  property real standardHeight: barHeight + gapsVert
  readonly property real borderMargin: C.Config.settings.panels.borders ? 1 : 0
  readonly property real topContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Top ? uncompactState : compactState) * gapsVert
  readonly property real bottomContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Bottom ? uncompactState : compactState) * gapsVert
  readonly property bool showBattery: UPower.displayDevice.isLaptopBattery
  property real compactState: compact ? 1 : 0
  property real uncompactState: 1 - compactState

  anchors: C.Config.barAnchors
  color: "transparent"
  exclusiveZone: compact ? compactHeight : standardHeight
  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: WlrLayer.Top
  implicitHeight: standardHeight

  visible: root.show

  // Background
  Rectangle {
    id: barBackground

    radius: root.uncompactState * root.barRadius
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? root.uncompactState * root.borderMargin : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)

    anchors {
      fill: parent
      leftMargin: root.uncompactState * root.gapsHorz
      rightMargin: root.uncompactState * root.gapsHorz
      topMargin: root.topContentMargin - root.borderMargin
      bottomMargin: root.bottomContentMargin - root.borderMargin
    }
  }

  // Title in the middle
  WindowTitle {
    id: barWindowTitle

    panelWindow: root
    anchors.centerIn: barBackground

    width: 500
  }

  RowLayout {
    // Left side
    spacing: 10

    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
    }

    LeftMenuButton {
      leftMargin: barBackground.anchors.leftMargin + root.borderMargin
      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      topLeftRadius: barBackground.radius - root.borderMargin
      bottomLeftRadius: topLeftRadius
    }

    BarSeparator {
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Workspaces {
      topInset: root.topContentMargin - root.borderMargin
      bottomInset: root.bottomContentMargin - root.borderMargin
      Layout.leftMargin: 8
      Layout.rightMargin: 8
    }

    BarSeparator {
      visible: barMpris.visible
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Mpris {
      id: barMpris

      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      Layout.maximumWidth: 350
    }
  }

  RowLayout {
    // Right side
    spacing: 15

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }

    Weather {
      opacity: C.Config.settings.bar.weather ? 1 : 0
      visible: opacity != 0
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    BarSeparator {
      opacity: C.Config.settings.bar.weather ? 1 : 0
      visible: opacity != 0
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    Battery {
      visible: root.showBattery
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      visible: root.showBattery
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Clock {
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    RightMenuButton {
      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      rightMargin: barBackground.anchors.rightMargin + root.borderMargin
      topRightRadius: barBackground.radius - root.borderMargin
      bottomRightRadius: topRightRadius
      Layout.leftMargin: -6
    }
  }

  Behavior on compactState {
    SmoothedAnimation {
      velocity: 8
    }
  }

  mask: Region {
    width: root.width
    height: root.exclusiveZone
  }
}
