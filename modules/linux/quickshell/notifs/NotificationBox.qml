import "../bar" as B
import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
  id: root

  required property TrackedNotification trackedNotif
  property string app: root.trackedNotif.notif.appName
  property string icon: root.trackedNotif.notif.appIcon
  property string summary: root.trackedNotif.notif.summary
  property string content: root.trackedNotif.notif.body
  property int indexPopup: -1
  property int indexAll: -1
  property bool hasDismiss: true
  property real iconSize: 46

  property real entryFactor: 1

  property real contentWidth: 360
  property real rightMargin: 20

  implicitWidth: box.implicitWidth + rightMargin
  implicitHeight: (box.implicitHeight + 5) * entryFactor

  Rectangle {
    id: box
    implicitWidth: root.contentWidth
    implicitHeight: mainLayout.implicitHeight + (root.trackedNotif.notif.actions.length != 0 ? 20 : 0)
    radius: 16
    color: C.Config.theme.background

    x: root.implicitWidth * (1 - root.entryFactor)

    RowLayout {
      id: mainLayout

      implicitHeight: contentLayout.implicitHeight
      spacing: 5

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
      }

      Item {
        id: coverItem

        Layout.alignment: Qt.AlignTop
        implicitWidth: root.iconSize
        implicitHeight: root.iconSize
        Layout.leftMargin: 15
        Layout.topMargin: 15

        ClippingWrapperRectangle {
          visible: root.icon != ""
          anchors.centerIn: parent
          radius: 15
          color: "transparent"

          IconImage {
            implicitSize: coverItem.height
            source: Quickshell.iconPath(root.icon)
          }
        }

        Rectangle {
          visible: root.icon == ""
          anchors.fill: parent
          radius: 15
          color: Qt.lighter(C.Config.theme.background)

          CW.FontIcon {
            text: ""
            anchors.centerIn: parent
            font.pointSize: 22
          }
        }
      }

      ColumnLayout {
        id: contentLayout

        Layout.fillWidth: true
        Layout.rightMargin: 15
        Layout.leftMargin: 15
        Layout.topMargin: 15
        Layout.bottomMargin: 15
        spacing: 5

        CW.StyledText {
          Layout.maximumWidth: contentLayout.width - buttonLayout.width
          text: `${root.summary} - ${root.app}`
          elide: Text.ElideRight
          font.pointSize: C.Config.fontSize.large
        }

        CW.HorizontalLine {
          Layout.leftMargin: 0
          Layout.fillWidth: false
          implicitWidth: 130
          Layout.bottomMargin: 0
        }

        CW.StyledText {
          Layout.fillWidth: true
          Layout.fillHeight: true
          font.pointSize: C.Config.fontSize.normal
          elide: Text.ElideRight
          text: root.content
        }
      }
    }

    RowLayout {
      id: buttonLayout
      implicitHeight: 22

      anchors {
        top: parent.top
        right: parent.right
        topMargin: 13
        rightMargin: 12
      }

      WrapperMouseArea {
        id: closeButtonMa

        hoverEnabled: true
        Layout.fillHeight: true
        implicitWidth: 22

        onPressed: root.trackedNotif.dismiss()

        Rectangle {
          radius: 16
          color: closeButtonMa.containsMouse ? Qt.lighter(Qt.lighter(Qt.lighter(C.Config.theme.background))) : Qt.lighter(Qt.lighter(C.Config.theme.background))
          implicitWidth: 22
          implicitHeight: 22

          CW.FontIcon {
            text: "close"
            anchors.centerIn: parent
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }

      WrapperMouseArea {
        id: dismissButtonMa

        visible: hasDismiss

        hoverEnabled: true
        Layout.fillHeight: true
        implicitWidth: 22

        onPressed: root.trackedNotif.hide()

        Rectangle {
          radius: 16
          color: dismissButtonMa.containsMouse ? Qt.lighter(Qt.lighter(Qt.lighter(C.Config.theme.background))) : Qt.lighter(Qt.lighter(C.Config.theme.background))
          implicitWidth: 22
          implicitHeight: 22

          CW.FontIcon {
            text: "chevron_right"
            anchors.centerIn: parent
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }
    }

    RowLayout {
      id: actionLayout
      implicitHeight: 22

      anchors {
        bottom: parent.bottom
        right: parent.right
        bottomMargin: 13
        rightMargin: 12
      }

      Repeater {
        model: root.trackedNotif.notif.actions

        WrapperMouseArea {
          required property int index

          id: actionMa

          hoverEnabled: true
          Layout.fillHeight: true

          onPressed: {
            root.trackedNotif.notif.actions[index].invoke()
            root.trackedNotif.hide()
          }

          Rectangle {
            radius: 6
            color: actionMa.containsMouse ? Qt.lighter(Qt.lighter(Qt.lighter(C.Config.theme.background))) : Qt.lighter(Qt.lighter(C.Config.theme.background))
            implicitWidth: textt.width + 15
            implicitHeight: 22

            CW.StyledText {
              id: textt
              text: root.trackedNotif.notif.actions[index].identifier
              anchors.centerIn: parent
            }

            Behavior on color {
              ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }
          }
        }
      }
    }

    ClippingRectangle {
      anchors.fill: parent
      radius: 16
      color: "transparent"
      visible: root.hasDismiss

      Rectangle {
        anchors {
          bottom: parent.bottom
          left: parent.left
        }
        width: parent.width * root.trackedNotif.timePercentage
        height: 2
        radius: 2
        color: Qt.darker(C.Config.theme.primary, 1.9)
      }
    }
  }
}
