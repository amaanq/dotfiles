import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtCore
import "../config" as C
import "../commonwidgets" as CW
import "../bar" as B
import "../state" as S

WrapperRectangle {
  id: root
  property real avatarSize: 50
  radius: 20
  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  margin: 15

  property bool hasSystemServiceIcon: false

  FileView {
    path: `/var/lib/AccountsService/icons/${S.SystemState.username}`
    onLoaded: {
      hasSystemServiceIcon = true;
    }
  }

  RowLayout {
    id: layout

    Item {
      id: coverItem
      Layout.fillHeight: true
      implicitHeight: root.avatarSize
      implicitWidth: root.avatarSize
      Layout.rightMargin: root.margin / 2

      ClippingWrapperRectangle {
        anchors.centerIn: parent
        radius: root.radius - root.margin
        color: "transparent"
        implicitHeight: root.avatarSize
        implicitWidth: root.avatarSize

        Image {
          width: root.avatarSize
          height: root.avatarSize
          source: hasSystemServiceIcon ? `/var/lib/AccountsService/icons/${S.SystemState.username}` : StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/avatar.jpg"
          sourceSize.width: root.avatarSize
          sourceSize.height: root.avatarSize
        }
      }
    }

    ColumnLayout {
      spacing: 2
      Layout.fillWidth: true
      CW.StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: (C.Config.account.username == "" ? S.SystemState.username : C.Config.account.username) + " on " + S.SystemState.host
      }
      CW.StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: S.SystemState.uptime
      }
    }
  }
}
