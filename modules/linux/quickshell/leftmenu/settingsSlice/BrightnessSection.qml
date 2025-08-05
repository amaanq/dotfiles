import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Rectangle {
  id: root

  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  radius: 8
  implicitHeight: 300

  ScrollView {
    id: scrollview

    anchors.fill: parent
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: scrollview.width
      uniformCellSizes: false
      spacing: -1

      anchors {
        top: parent.top
        left: parent.left
      }

      CW.StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 10
        text: "Brightness"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h2
        color: C.Config.theme.on_surface
      }

      Spacerr {}

      CW.HorizontalLine {}

      Spacerr {}

      BrightnessSlider {
        visible: S.BrightnessState.hasBacklight && C.Config.misc.brightnessSplit
        label: "Backlight"
        value: S.BrightnessState.backlightBrightness
        Layout.fillWidth: true
        onMoved: S.BrightnessState.setBacklight(value)
        Layout.leftMargin: 15
        Layout.rightMargin: 15
      }

      BrightnessSlider {
        visible: !C.Config.misc.brightnessSplit
        label: "Brightness"
        value: S.BrightnessState.overallBrightness
        Layout.fillWidth: true
        onMoved: S.BrightnessState.setOverall(value)
        Layout.leftMargin: 15
        Layout.rightMargin: 15
      }

      Spacerr {
        visible: (!C.Config.misc.brightnessSplit) || (S.BrightnessState.hasBacklight && C.Config.misc.brightnessSplit)
      }

      ColumnLayout {
        spacing: 5

        Repeater {
          visible: C.Config.misc.brightnessSplit
          model: S.BrightnessState.monitors

          BrightnessSlider {
            required property int index

            visible: S.BrightnessState.brightnesses[index] != -1 && C.Config.misc.brightnessSplit
            label: S.BrightnessState.monitors[index]
            value: S.BrightnessState.brightnesses[index]
            Layout.fillWidth: true
            onMoved: S.BrightnessState.setBrightness(index, value)
            Layout.leftMargin: 15
            Layout.rightMargin: 15
          }
        }
      }

      Spacerr {}

      CW.StyledText {
        visible: C.Config.misc.brightnessSplit && !S.BrightnessState.anyControls
        Layout.fillWidth: true
        text: "No display supports brightness controls"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.small
        color: Qt.darker(C.Config.theme.on_surface)
      }

      Spacerr {}

      CW.StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 20
        text: "Night Light"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h2
        color: C.Config.theme.on_surface
      }

      Spacerr {}

      CW.HorizontalLine {}

      Spacerr {}

      CW.ValueSwitch {
        Layout.fillWidth: true
        Layout.leftMargin: 18.5
        Layout.rightMargin: 15
        label: "Enable night light"
        checked: C.Config.misc.nightLightEnabled
        onToggled: {
          C.Config.misc.nightLightEnabled = checked;
          S.NightLightState.setIntensity(C.Config.misc.nightLightIntense);
        }
      }

      Spacerr {}

      BrightnessSlider {
        label: "Night light intensity"
        icon: "bedtime"
        Layout.fillWidth: true
        Layout.leftMargin: 15
        Layout.rightMargin: 15
        visible: opacity != 0
        value: C.Config.misc.nightLightIntense
        opacity: C.Config.misc.nightLightEnabled ? 1 : 0
        Layout.preferredHeight: C.Config.misc.nightLightEnabled ? implicitHeight : 0

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        onMoved: {
          C.Config.misc.nightLightIntense = value;
          S.NightLightState.setIntensity(value);
        }
      }

      Spacerr {
        Layout.preferredHeight: C.Config.misc.nightLightEnabled ? 11 : -1
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_NORMAL
            easing.type: Easing.Linear
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }
    }
  }

  // this is horrible but QML has forced my hand.
  component Spacerr: Item {
    Layout.preferredHeight: 11
  }
}
