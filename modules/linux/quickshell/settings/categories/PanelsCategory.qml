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
                text: "General"

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

            CW.ValueSwitch {
                label: "Transparent"
                checked: C.Config.settings.panels.transparent
                onToggled: C.Config.settings.panels.transparent = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.SliderValue {
                visible: opacity != 0
                label: "Base opacity"
                from: 0.42
                to: 1
                floatVal: true
                value: C.Config.settings.panels.baseOpacity
                onMoved: C.Config.settings.panels.baseOpacity = value
                Layout.preferredHeight: C.Config.settings.panels.transparent ? implicitHeight : 0
                opacity: C.Config.settings.panels.transparent ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                Layout.preferredHeight: C.Config.settings.panels.transparent ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                label: "Panel border"
                checked: C.Config.settings.panels.borders
                onToggled: C.Config.settings.panels.borders = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.SliderValue {
                visible: opacity != 0
                label: "Border width"
                from: 1
                to: 5
                floatVal: false
                value: C.Config.settings.panels.bordersSize
                onMoved: C.Config.settings.panels.bordersSize = Math.round(value)
                Layout.preferredHeight: C.Config.settings.panels.borders ? implicitHeight : 0
                opacity: C.Config.settings.panels.borders ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                visible: Layout.preferredHeight != -1
                Layout.preferredHeight: C.Config.settings.panels.borders ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                label: "Compact on maximized"
                checked: C.Config.settings.panels.compactEnabled
                onToggled: C.Config.settings.panels.compactEnabled = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.SliderValue {
                label: "Corner radius"
                from: 0
                to: 20
                value: C.Config.settings.panels.radius
                onMoved: C.Config.settings.panels.radius = Math.round(value)
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Monitors"

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
                label: "Monitor choice mode"
                value: C.Config.settings.panels.monitorChoiceMode
                values: ["Exclude", "Include"]
                onMoved: C.Config.settings.panels.monitorChoiceMode = Math.round(value)
            }

            Spacerr {
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: widgetsTv1.height

                ST.TextValue {
                    id: widgetsTv1

                    visible: opacity != 0
                    opacity: C.Config.settings.panels.monitorChoiceMode == 0 ? 1 : 0
                    z: C.Config.settings.panels.monitorChoiceMode == 0 ? 3 : 2
                    label: "Don't show widgets on"
                    value: asMonitorString(C.Config.settings.panels.excludedMonitors)
                    onChanged: (x) => {
                        let arr = fromCommaList(x);
                        if (arr == [])
                            return ;

                        C.Config.settings.panels.excludedMonitors = arr;
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
                    opacity: C.Config.settings.panels.monitorChoiceMode == 1 ? 1 : 0
                    z: C.Config.settings.panels.monitorChoiceMode == 1 ? 3 : 2
                    label: "Show widgets on"
                    value: asMonitorString(C.Config.settings.panels.includedMonitors)
                    onChanged: (x) => {
                        let arr = fromCommaList(x);
                        if (arr == [])
                            return ;

                        C.Config.settings.panels.includedMonitors = arr;
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

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Monitor Rounding"

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

            CW.ValueSwitch {
                label: "Enabled"
                checked: C.Config.settings.monitorRounding.enabled
                onToggled: C.Config.settings.monitorRounding.enabled = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.SliderValue {
                visible: opacity != 0
                label: "Size"
                from: 5
                to: 40
                floatVal: false
                value: C.Config.settings.monitorRounding.radius
                onMoved: C.Config.settings.monitorRounding.radius = Math.round(value)
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? implicitHeight : 0
                opacity: C.Config.settings.monitorRounding.enabled ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                visible: Layout.preferredHeight != -1
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                label: "Ignore Reserved"
                checked: C.Config.settings.monitorRounding.ignoreReserved
                onToggled: C.Config.settings.monitorRounding.ignoreReserved = checked
                Layout.fillWidth: true
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? implicitHeight : 0
                opacity: C.Config.settings.monitorRounding.enabled ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                visible: Layout.preferredHeight != -1
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                label: "AMOLED Black"
                checked: C.Config.settings.monitorRounding.amoled
                onToggled: C.Config.settings.monitorRounding.amoled = checked
                Layout.fillWidth: true
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? implicitHeight : 0
                opacity: C.Config.settings.monitorRounding.enabled ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                visible: Layout.preferredHeight != -1
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                label: "Show on all monitors"
                checked: C.Config.settings.monitorRounding.allMonitors
                onToggled: C.Config.settings.monitorRounding.allMonitors = checked
                Layout.fillWidth: true
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? implicitHeight : 0
                opacity: C.Config.settings.monitorRounding.enabled ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                visible: Layout.preferredHeight != -1
                Layout.preferredHeight: C.Config.settings.monitorRounding.enabled ? 11 : -1

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_NORMAL
                        easing.type: Easing.Linear
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

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
                text: "Home Panel"

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

            CW.ValueSwitch {
                label: "Per-monitor brightness control"
                checked: C.Config.misc.brightnessSplit
                onToggled: C.Config.misc.brightnessSplit = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Monochrome tray icons"
                checked: C.Config.settings.tray.monochromeIcons
                onToggled: C.Config.settings.tray.monochromeIcons = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "On Screen Display"

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

            ST.SpinBoxValue {
                label: "Timeout duration"
                from: 100
                to: 2000
                stepSize: 100
                value: C.Config.settings.osd.timeoutDuration
                onMoved: C.Config.settings.osd.timeoutDuration = value
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Fonts"

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

            ST.SliderValue {
                label: "Base font size"
                from: 8
                to: 14
                value: C.Config.settings.fonts.basePointSize
                onMoved: C.Config.settings.fonts.basePointSize = Math.round(value)
                Layout.fillWidth: true
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Use native rendering"
                checked: C.Config.settings.fonts.useNativeRendering
                onToggled: C.Config.settings.fonts.useNativeRendering = checked
                Layout.fillWidth: true
            }

        }

    }

    // this is horrible but QML has forced my hand.
    component Spacerr: Item {
        Layout.preferredHeight: 11
    }

}
