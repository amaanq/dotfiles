import "../../commonwidgets" as CW
import "../../config" as C
import "./settings" as ST
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

CategoryBlueprint {
    id: root

    RowLayout {
        spacing: 50
        anchors.margins: 20
        uniformCellSizes: false

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        ColumnLayout {
            id: col1

            Layout.fillWidth: true
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            uniformCellSizes: false
            spacing: 0

            CW.StyledText {
                Layout.topMargin: 10
                text: "Date"

                font {
                    pointSize: C.Config.fontSize.h2
                    weight: Font.DemiBold
                }

            }

            Spacerr {
            }

            CW.HorizontalLine {
                Layout.topMargin: -5
                Layout.bottomMargin: 5
                Layout.fillWidth: false
                Layout.leftMargin: 0
                implicitWidth: 90
            }

            Spacerr {
            }

            ST.ChoiceBoxValue {
                label: "Date format"
                value: C.Config.settings.misc.dateFormat
                values: ["Standard", "Leading", "12-hour", "American", "Full English", "Polish"]
                onMoved: C.Config.settings.misc.dateFormat = Math.round(value)
            }

        }

        ColumnLayout {
            id: col2

            Layout.fillWidth: true
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            uniformCellSizes: false
            spacing: 0

            CW.StyledText {
                Layout.topMargin: 10
                text: "MPRIS"

                font {
                    pointSize: C.Config.fontSize.h2
                    weight: Font.DemiBold
                }

            }

            Spacerr {
            }

            CW.HorizontalLine {
                Layout.topMargin: -5
                Layout.bottomMargin: 5
                Layout.fillWidth: false
                Layout.leftMargin: 0
                implicitWidth: 90
            }

            Spacerr {
            }

            ST.ChoiceBoxValue {
                label: "MPRIS player mode"
                value: C.Config.settings.mpris.selectionMode
                values: ["Exclude", "Include"]
                onMoved: C.Config.settings.mpris.selectionMode = Math.round(value)
            }

            Spacerr {
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: widgetsTv2.height

                ST.TextValue {
                    id: widgetsTv2

                    visible: opacity != 0
                    opacity: C.Config.settings.mpris.selectionMode == 0 ? 1 : 0
                    z: C.Config.settings.mpris.selectionMode == 0 ? 3 : 2
                    label: "Exclude players"
                    value: asMonitorString(C.Config.settings.mpris.excludedPlayers)
                    onChanged: (x) => {
                        let arr = fromCommaList(x);
                        if (arr == [])
                            return ;

                        C.Config.settings.mpris.excludedPlayers = arr;
                    }

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: C.Globals.anim_MEDIUM
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                        }

                    }

                }

                ST.TextValue {
                    visible: opacity != 0
                    opacity: C.Config.settings.mpris.selectionMode == 1 ? 1 : 0
                    z: C.Config.settings.mpris.selectionMode == 1 ? 3 : 2
                    label: "Include players"
                    value: asMonitorString(C.Config.settings.mpris.includedPlayers)
                    onChanged: (x) => {
                        let arr = fromCommaList(x);
                        if (arr == [])
                            return ;

                        C.Config.settings.mpris.includedPlayers = arr;
                    }

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
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

}
