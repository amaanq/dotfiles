import "../../config" as C
import "../../commonwidgets" as CW
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
  id: root

  anchors.fill: parent

  function asMonitorString(mons) {
    return mons.join(",");
  }

  function fromCommaList(str) {
    var mnames = str.split(",");
    var arr = [];
    for (var mn of mnames) {
      arr = [mn.trim(), ...arr];
    }
    return arr;
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.h1
    text: "Settings"
  }

  CW.HorizontalLine {}

  ScrollView {
    id: sv

    Layout.fillHeight: true
    Layout.fillWidth: true
    ScrollBar.horizontal: null
    ScrollBar.vertical: CW.StyledScrollBar {
      anchors {
        left: parent.right
        leftMargin: 6
        top: parent.top
        bottom: parent.bottom
      }
    }

    ColumnLayout {
      implicitWidth: sv.width
      spacing: -1

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
        text: "Bar"
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Bar on top"
        checked: C.Config.settings.bar.edge == "top"
        onToggled: C.Config.settings.bar.edge = checked ? "top" : "bottom"
      }

      Spacerr {}

      SliderValue {
        label: "Vertical Gap"
        from: 0
        to: 15
        value: C.Config.settings.bar.verticalGap
        onMoved: C.Config.settings.bar.verticalGap = Math.round(value)
      }

      Spacerr {}

      SliderValue {
        label: "Horizontal Gap"
        from: 0
        to: 15
        value: C.Config.settings.bar.horizontalGap
        onMoved: C.Config.settings.bar.horizontalGap = Math.round(value)
      }

      Spacerr {}

      SliderValue {
        label: "Height"
        from: 25
        to: 45
        value: C.Config.settings.bar.height
        onMoved: C.Config.settings.bar.height = Math.round(value)
      }

      Spacerr {}

      SliderValue {
        label: "Corner radius"
        from: 0
        to: 20
        value: C.Config.settings.panels.radius
        onMoved: C.Config.settings.panels.radius = Math.round(value)
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h3
          weight: Font.Medium
        }
        text: "Workspaces"
      }

      Spacerr {}

      SliderValue {
        label: "Active indicator width"
        from: 1
        to: 4
        value: C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier
        onMoved: C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier = Math.round(value * 10.0) / 10.0
        floatVal: true
      }

      Spacerr {}

      ChoiceBoxValue {
        implicitWidth: sv.width
        label: "Indicator style"
        value: C.Config.settings.bar.workspaces.style
        values: ["Round", "Numbers", "Roman"]
        onMoved: C.Config.settings.bar.workspaces.style = Math.round(value)
      }

      Spacerr {}

      SpinBoxValue {
        label: "Workspaces shown"
        from: 1
        to: 15
        value: C.Config.settings.bar.workspaces.shown
        onMoved: C.Config.settings.bar.workspaces.shown = Math.round(value)
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Only current monitor"
        checked: C.Config.settings.bar.workspaces.onlyOnCurrent
        onToggled: C.Config.settings.bar.workspaces.onlyOnCurrent = checked
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h3
          weight: Font.Medium
        }
        text: "Battery"
      }

      Spacerr {}

      SpinBoxValue {
        label: "Low Battery Threshold"
        from: 10
        to: 50
        value: C.Config.settings.bar.battery.low
        onMoved: C.Config.settings.bar.battery.low = Math.round(value)
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h3
          weight: Font.Medium
        }
        text: "Weather"
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Enable Weather"
        sublabel: "Uses ipinfo.io and wttr.in"
        checked: C.Config.settings.bar.weather
        onToggled: C.Config.settings.bar.weather = checked
      }

      Spacerr {}

      TextValue {
        visible: opacity != 0
        opacity: C.Config.settings.bar.weather ? 1 : 0
        Layout.preferredHeight: C.Config.settings.bar.weather ? implicitHeight : 0
        z: C.Config.settings.bar.weather ? 3 : 2
        label: "Override Location"
        value: C.Config.settings.bar.weatherLocation
        onChanged: x => {
          C.Config.settings.bar.weatherLocation = x;
        }

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_MEDIUM
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_MEDIUM
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }

      Spacerr {
        Layout.preferredHeight: C.Config.settings.bar.weather ? 11 : 0
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_MEDIUM
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
        text: "Panels"
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Transparent"
        checked: C.Config.settings.panels.transparent
        onToggled: C.Config.settings.panels.transparent = checked
      }

      Spacerr {}

      SliderValue {
        visible: opacity != 0
        label: "Base opacity"
        from: 0.42
        to: 1.0
        floatVal: true
        value: C.Config.settings.panels.baseOpacity
        onMoved: C.Config.settings.panels.baseOpacity = value

        Layout.preferredHeight: C.Config.settings.panels.transparent ? implicitHeight : 0
        opacity: C.Config.settings.panels.transparent ? 1 : 0

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_NORMAL
            easing.type: Easing.Linear
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_NORMAL
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }

      Spacerr {
        Layout.preferredHeight: C.Config.settings.panels.transparent ? 11 : -1
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_NORMAL
            easing.type: Easing.Linear
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Panel border"
        checked: C.Config.settings.panels.borders
        onToggled: C.Config.settings.panels.borders = checked
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Compact on maximized"
        checked: C.Config.settings.panels.compactEnabled
        onToggled: C.Config.settings.panels.compactEnabled = checked
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h3
          weight: Font.Medium
        }
        text: "Monitors"
      }

      Spacerr {}

      ChoiceBoxValue {
        implicitWidth: sv.width
        label: "Monitor choice mode"
        value: C.Config.settings.panels.monitorChoiceMode
        values: ["Exclude", "Include"]
        onMoved: C.Config.settings.panels.monitorChoiceMode = Math.round(value)
      }

      Spacerr {}

      Item {
        Layout.fillWidth: true
        implicitHeight: widgetsTv1.height

        TextValue {
          id: widgetsTv1
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          visible: opacity != 0
          opacity: C.Config.settings.panels.monitorChoiceMode == 0 ? 1 : 0
          z: C.Config.settings.panels.monitorChoiceMode == 0 ? 3 : 2
          label: "Don't show widgets on"
          value: asMonitorString(C.Config.settings.panels.excludedMonitors)
          onChanged: x => {
            let arr = fromCommaList(x);
            if (arr == [])
              return;

            C.Config.settings.panels.excludedMonitors = arr;
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }

        TextValue {
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          visible: opacity != 0
          opacity: C.Config.settings.panels.monitorChoiceMode == 1 ? 1 : 0
          z: C.Config.settings.panels.monitorChoiceMode == 1 ? 3 : 2
          label: "Show widgets on"
          value: asMonitorString(C.Config.settings.panels.includedMonitors)
          onChanged: x => {
            let arr = fromCommaList(x);
            if (arr == [])
              return;

            C.Config.settings.panels.includedMonitors = arr;
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h3
          weight: Font.Medium
        }
        text: "Home Panel"
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Per-monitor brightness control"
        checked: C.Config.misc.brightnessSplit
        onToggled: C.Config.misc.brightnessSplit = checked
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Monochrome tray icons"
        checked: C.Config.settings.tray.monochromeIcons
        onToggled: C.Config.settings.tray.monochromeIcons = checked
      }

      Spacerr {}

      CW.StyledText {
        text: "On-screen display"
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      SpinBoxValue {
        label: "Timeout duration"
        from: 100
        to: 2000
        stepSize: 100
        value: C.Config.settings.osd.timeoutDuration
        onMoved: C.Config.settings.osd.timeoutDuration = value
      }

      Spacerr {}

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
        text: "Fonts"
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      SliderValue {
        label: "Base font size"
        from: 8
        to: 14
        value: C.Config.settings.fonts.basePointSize
        onMoved: C.Config.settings.fonts.basePointSize = Math.round(value)
      }

      Spacerr {}

      CW.ValueSwitch {
        implicitWidth: sv.width
        label: "Use native rendering"
        checked: C.Config.settings.fonts.useNativeRendering
        onToggled: C.Config.settings.fonts.useNativeRendering = checked
      }

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
        text: "Miscellaneous"
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      ChoiceBoxValue {
        implicitWidth: sv.width
        label: "Date format"
        value: C.Config.settings.misc.dateFormat
        values: ["Standard", "Leading", "12-hour", "American", "Full English", "Polish"]
        onMoved: C.Config.settings.misc.dateFormat = Math.round(value)
      }

      CW.StyledText {
        Layout.topMargin: 10
        font {
          pointSize: C.Config.fontSize.h2
          weight: Font.DemiBold
        }
        text: "MPRIS"
      }

      Spacerr {}

      CW.HorizontalLine {
        Layout.topMargin: -5
        Layout.bottomMargin: 5
        Layout.fillWidth: false
        Layout.leftMargin: 0
        implicitWidth: 90
      }

      Spacerr {}

      ChoiceBoxValue {
        implicitWidth: sv.width
        label: "MPRIS player mode"
        value: C.Config.settings.mpris.selectionMode
        values: ["Exclude", "Include"]
        onMoved: C.Config.settings.mpris.selectionMode = Math.round(value)
      }

      Spacerr {}

      Item {
        Layout.fillWidth: true
        implicitHeight: widgetsTv2.height

        TextValue {
          id: widgetsTv2
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          visible: opacity != 0
          opacity: C.Config.settings.mpris.selectionMode == 0 ? 1 : 0
          z: C.Config.settings.mpris.selectionMode == 0 ? 3 : 2
          label: "Exclude players"
          value: asMonitorString(C.Config.settings.mpris.excludedPlayers)
          onChanged: x => {
            let arr = fromCommaList(x);
            if (arr == [])
              return;

            C.Config.settings.mpris.excludedPlayers = arr;
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }

        TextValue {
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          visible: opacity != 0
          opacity: C.Config.settings.mpris.selectionMode == 1 ? 1 : 0
          z: C.Config.settings.mpris.selectionMode == 1 ? 3 : 2
          label: "Include players"
          value: asMonitorString(C.Config.settings.mpris.includedPlayers)
          onChanged: x => {
            let arr = fromCommaList(x);
            if (arr == [])
              return;

            C.Config.settings.mpris.includedPlayers = arr;
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }

    }
  }

  // this is horrible but QML has forced my hand.
  component Spacerr: Item {
    Layout.preferredHeight: 11
  }

  CW.StyledText {
    font.pointSize: C.Config.fontSize.small
    text: "For Hyprland settings, see ~/.config/hypr/conf.d/custom.d/"
    color: Qt.darker(C.Config.theme.on_surface)
  }
}
