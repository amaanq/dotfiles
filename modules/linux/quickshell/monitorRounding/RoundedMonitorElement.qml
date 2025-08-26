import QtQuick // for Text
import QtQuick.Layouts
import Quickshell // for ShellRoot and PanelWindow
import Quickshell.DBusMenu
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../config" as C

WlrLayershell {
    id: root

    property bool show: false
    property int cornerSize: C.Config.settings.monitorRounding.radius
    property var cornerColor: C.Config.settings.monitorRounding.amoled ? "#000000" : C.Config.applyBaseOpacity(C.Config.theme.background)

    exclusionMode: C.Config.settings.monitorRounding.ignoreReserved ? ExclusionMode.Ignore : ExclusionMode.Normal
    layer: C.Config.settings.bar.topLayer ? WlrLayer.Top : WlrLayer.Bottom
    namespace: "hyprland-shell:rounding"
    visible: root.show
    color: "transparent"
    mask: Region {}

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: () => {
            // FIXME: this is genuinely atrocious, but qml doesn't render the shape correctly without this nudge?
            // Might be a QTBUG
            if (cornerSize == C.Config.settings.monitorRounding.radius) {
                cornerSize = C.Config.settings.monitorRounding.radius + 1;
                cornerSize = C.Config.settings.monitorRounding.radius;
            }
        }
    }

    anchors {
        bottom: true
        right: true
        left: true
        top: true
    }

    margins {
        bottom: 0
        right: 0
        left: 0
        top: 0
    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 0
        fillColor: root.cornerColor

        anchors {
            left: parent.left
            top: parent.top
        }

    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 1
        fillColor: root.cornerColor

        anchors {
            right: parent.right
            top: parent.top
        }

    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 3
        fillColor: root.cornerColor

        anchors {
            right: parent.right
            bottom: parent.bottom
        }

    }

    RoundedEdge {
        cornerSize: root.cornerSize
        corner: 2
        fillColor: root.cornerColor

        anchors {
            left: parent.left
            bottom: parent.bottom
        }

    }

}
