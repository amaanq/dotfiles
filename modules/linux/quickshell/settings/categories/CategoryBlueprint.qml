import "../../commonwidgets" as CW
import "../../config" as C
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

ScrollView {
    id: root

    ScrollBar.horizontal: null
    contentWidth: root.width

    ScrollBar.vertical: CW.StyledScrollBar {
        anchors {
            left: parent.right
            leftMargin: 6
            top: parent.top
            bottom: parent.bottom
        }

    }

}
