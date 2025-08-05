import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Rectangle {
  id: root

  property list<PwNode> appPwNodes: Pipewire.nodes.values.filter(node => {
    return (node.isSink || node.isStream) && node != S.PipewireState.defaultSink;
  }).sort((a, b) => {
    if (a.isSink && !a.isStream)
      return b.isSink && !b.isStream ? 0 : -1;
    return 1;
  })

  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  radius: 8
  implicitHeight: 300

  ColumnLayout {
    anchors.fill: parent

    CW.StyledText {
      Layout.fillWidth: true
      Layout.topMargin: 10
      text: "Volume mixer"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
    }

    CW.HorizontalLine {
      Layout.topMargin: 4
      Layout.bottomMargin: 4
    }

    VolumeMixerEntry {
      overrideIcon: "speaker"
      node: S.PipewireState.defaultSink
      isDefault: true
      canBeDefault: true
      isMuted: S.PipewireState.defaultSink.audio.muted == true
      Layout.fillWidth: true
      Layout.leftMargin: 15
      Layout.rightMargin: 15
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      spacing: 10

      model: root.appPwNodes
      delegate: VolumeMixerEntry {
        required property PwNode modelData
        node: modelData
        isDefault: modelData == S.PipewireState.defaultSink
        canBeDefault: modelData.isSink && !modelData.isStream
        isMuted: modelData.audio.muted == true
        anchors {
          left: parent.left
          right: parent.right
          leftMargin: 15
          rightMargin: 15
        }
      }
    }
  }
}
