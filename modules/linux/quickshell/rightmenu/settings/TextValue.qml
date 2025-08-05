import "../../bar" as B
import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RowLayout {
  id: root

  property string label: "Vaxry was here"
  property string value: "Test"
  property var onChanged: function (x) {
    console.log("BUG THIS: empty onChanged in TextValue.qml");
  }

  RowLayout {
    Text {
      Layout.fillHeight: true
      font.pointSize: C.Config.fontSize.normal
      text: label
      verticalAlignment: Text.AlignVCenter
      color: C.Config.theme.on_surface
    }

    Item {
      Layout.fillWidth: true
    }

    Rectangle {
      Layout.fillHeight: true
      Layout.preferredWidth: te.width + 20
      color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
      radius: 6

      TextEdit {
        id: te

        font.pointSize: C.Config.fontSize.normal
        text: value.length < 1 ? "None" : value
        verticalAlignment: Text.AlignVCenter
        color: C.Config.theme.on_surface
        onEditingFinished: {
          onChanged(te.text);
        }
        onTextEdited: {
          if (te.text.indexOf("\n") != -1) {
            te.text = te.text.trim();
            te.deselect();
            onChanged(te.text);
          }
        }

        anchors {
          top: parent.top
          bottom: parent.bottom
          right: parent.right
          rightMargin: 10
        }
      }
    }
  }
}
