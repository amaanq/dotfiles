import "../config" as C
import "./settingsSlice" as SL
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

WrapperItem {
  id: root

  property var activeSection: null

  ColumnLayout {
    spacing: 0

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 5
      implicitHeight: 20

      SectionButton {
        icon: "wifi" // TODO: replace this to reflect signal strength
        section: wifiSection
      }

      SectionButton {
        icon: "bluetooth" // TODO: replace this to reflect bluetooth state
        section: bluetoothSection
      }

      SectionButton {
        icon: "brightness_6"
        section: brightnessSection
      }

      SectionButton {
        icon: "volume_up"
        section: audioSection
      }
    }

    Item {
      Layout.fillWidth: true
      implicitHeight: root.activeSection == null ? 0 : root.activeSection.height + 5
      visible: implicitHeight != 0
      clip: heightAnim.running

      Behavior on implicitHeight {
        NumberAnimation {
          id: heightAnim
          duration: C.Globals.anim_SLOW * 1.1
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      Item {
        anchors.fill: parent
        anchors.topMargin: 5

        SL.WifiSection {
          id: wifiSection

          visible: opacity != 0
          opacity: root.activeSection == this ? 1 : 0
          layer.enabled: opacity != 1.0
          z: root.activeSection == this ? 2 : 1

          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }

        SL.BrightnessSection {
          id: brightnessSection

          visible: opacity != 0
          opacity: root.activeSection == this ? 1 : 0
          layer.enabled: opacity != 1.0
          z: root.activeSection == this ? 2 : 1

          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }

        SL.AudioSection {
          id: audioSection

          visible: opacity != 0
          opacity: root.activeSection == this ? 1 : 0
          layer.enabled: opacity != 1.0
          z: root.activeSection == this ? 2 : 1

          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }

          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_MEDIUM
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }

        SL.BluetoothSection {
          id: bluetoothSection

          visible: opacity != 0
          opacity: root.activeSection == this ? 1 : 0
          layer.enabled: opacity != 1.0
          z: root.activeSection == this ? 2 : 1

          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
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

  component SectionButton: WrapperMouseArea {
    id: button

    required property var section
    property alias icon: sb.icon

    hoverEnabled: true
    onPressed: {
      if (root.activeSection == section)
        root.activeSection = null;
      else
        root.activeSection = section;
    }

    SL.SectionButton {
      id: sb

      hovered: button.containsMouse
      active: root.activeSection == button.section
    }
  }
}
