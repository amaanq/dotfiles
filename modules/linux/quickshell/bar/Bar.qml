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
  property real barRadius: C.Config.settings.bar.radius
  property real barHeight: C.Config.settings.bar.height
  property real gapsHorz: C.Config.settings.bar.horizontalGap
  property real gapsVert: C.Config.settings.bar.verticalGap
  property real innerPadHorz: 8
  property real compactHeight: barHeight
  property real standardHeight: barHeight + gapsVert
  readonly property real borderMargin: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
  readonly property real topContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Top ? uncompactState : compactState) * gapsVert
  readonly property real bottomContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Bottom ? uncompactState : compactState) * gapsVert
  readonly property bool showBattery: UPower.displayDevice.isLaptopBattery
  property real compactState: compact ? 1 : 0
  property real uncompactState: 1 - compactState

  anchors: C.Config.barAnchors
  color: "transparent"
  exclusiveZone: compact ? compactHeight : standardHeight
  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: C.Config.settings.bar.topLayer ? WlrLayer.Top : WlrLayer.Bottom
  implicitHeight: standardHeight

  visible: root.show

  function stringToModule(str) {
    let t = str.trim();

    if (t == "workspaces")
      return workspaces;
    if (t == "mpris")
      return barMpris;
    if (t == "weather")
      return C.Config.settings.bar.weather ? weather : null;
    if (t == "battery")
      return battery.visible ? battery : null;
    if (t == "clock")
      return clock;
    if (t == "title")
      return barWindowTitle;
    if (t == "keyboard")
      return barKeyboard;
    return null;
  }

  function getLeftChildren() {
    let modules = C.Config.settings.bar.modulesLeft.split(',');
    let sepI = 0;
    const seps = [separator, separator2, separator3, separator4, separator5, separator6, separator7];

    let moduleArr = [];

    for (let mstr of modules) {
      let mod = stringToModule(mstr);
      if (mod == null) {
        console.log("module " + mstr + " was null");
        continue;
      }

      moduleArr.push(seps[sepI++]);
      moduleArr.push(mod);
    }

    return moduleArr;
  }

  function getRightChildren() {
    let modules = C.Config.settings.bar.modulesRight.split(',');
    let sepI = 0;
    const seps = [separatora, separator2a, separator3a, separator4a, separator5a, separator6a, separator7a];

    let moduleArr = [];

    for (let mstr of modules) {
      let mod = stringToModule(mstr);
      if (mod == null) {
        console.log("module " + mstr + " was null");
        continue;
      }

      moduleArr.push(seps[sepI++]);
      moduleArr.push(mod);
    }

    return moduleArr.reverse();
  }

  function getMiddleChild() {
    return [stringToModule(C.Config.settings.bar.moduleCenter)]
  }

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
  RowLayout {
    anchors.centerIn: barBackground

    children: [...getMiddleChild()]
  }

  RowLayout {
    // Left side
    spacing: 10

    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
    }

    children: [leftMenuButton, ...getLeftChildren()]
  }

  RowLayout {
    // Right side
    spacing: 15

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }

    children: [...getRightChildren(), rightMenuButton]
  }

  Behavior on compactState {
    SmoothedAnimation {
      velocity: 8
    }
  }

  Item {
    visible: false

    LeftMenuButton {
      id: leftMenuButton
      leftMargin: barBackground.anchors.leftMargin + root.borderMargin
      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      topLeftRadius: barBackground.radius - root.borderMargin
      bottomLeftRadius: topLeftRadius
    }

    WindowTitle {
      id: barWindowTitle
      panelWindow: root
    }

    // FIXME: this SUCKS
    BarSeparator {
      id: separator
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator2
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator3
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator4
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator5
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator6
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator7
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separatora
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator2a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator3a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator4a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator5a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator6a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    BarSeparator {
      id: separator7a
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Workspaces {
      id: workspaces
      topInset: root.topContentMargin - root.borderMargin
      bottomInset: root.bottomContentMargin - root.borderMargin
      Layout.leftMargin: 8
      Layout.rightMargin: 8
    }

    Mpris {
      id: barMpris

      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      Layout.maximumWidth: 350
    }

    Weather {
      id: weather
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Battery {
      id: battery
      visible: root.showBattery
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    Clock {
      id: clock
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    KeyboardLayout {
      id: barKeyboard
      Layout.topMargin: root.topContentMargin
      Layout.bottomMargin: root.bottomContentMargin
    }

    RightMenuButton {
      id: rightMenuButton
      topMargin: root.topContentMargin
      bottomMargin: root.bottomContentMargin
      rightMargin: barBackground.anchors.rightMargin + root.borderMargin
      topRightRadius: barBackground.radius - root.borderMargin
      bottomRightRadius: topRightRadius
      Layout.leftMargin: -6
    }
  }

  mask: Region {
    width: root.width
    height: root.exclusiveZone
  }
}
