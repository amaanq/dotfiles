import "../" as P
import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
  id: root

  anchors.fill: parent
  spacing: 10

  Item {
    Layout.fillHeight: true
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.h1
    text: "Updates"
  }

  CW.HorizontalLine {
    Layout.bottomMargin: 20
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.large
    text: S.UpdateState.updateRunning ? "An update is running..." : (S.UpdateState.updatesAvailable ? "Updates available!" : "Already up-to-date.")
  }

  CW.HorizontalLine {
    Layout.leftMargin: 80
    Layout.rightMargin: 80
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.normal
    text: "Last update check: " + C.Config.epochSecondsToHuman(C.Config.misc.lastUpdateCheck)
  }

  CW.StyledText {
    visible: S.UpdateState.lastUpdateCheckFailed
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.normal
    text: "Last update check failed, possible reasons include being offline, subscription expiring, or login details being changed. You can try logging again below. The server returned: " + S.UpdateState.lastUpdateCheckFailedReason
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  CW.StyledButton {
    Layout.alignment: Qt.AlignHCenter
    label: S.UpdateState.lastUpdateCheckFailed ? "Try again" : "Check for updates"
    onClicked: {
      S.UpdateState.checkForUpdates();
    }
  }

  CW.StyledButton {
    visible: S.UpdateState.lastUpdateCheckFailed && !S.UpdateState.updateRunning
    Layout.alignment: Qt.AlignHCenter
    label: "Log in again"
    onClicked: {
      S.UpdateState.relog();
    }
  }

  Item {
    Layout.fillHeight: true
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.small
    text: "<i>Curious what changed? Check the pinned Hyprland DE Changelog thread on the forums in the Hyprland DE category.</i>"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    opacity: 0.9
  }

  Item {
    Layout.preferredHeight: 40
  }

  P.UpdateBar {
    Layout.fillWidth: true
    visible: opacity != 0
    opacity: S.UpdateState.updatesAvailable ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: 400
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }

    Layout.bottomMargin: 35
  }
}
