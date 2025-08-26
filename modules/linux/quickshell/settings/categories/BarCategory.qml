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
                label: "Bar on top"
                checked: C.Config.settings.bar.edge == "top"
                onToggled: C.Config.settings.bar.edge = checked ? "top" : "bottom"
                Layout.fillWidth: true
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Bar above windows"
                checked: C.Config.settings.bar.topLayer
                onToggled: C.Config.settings.bar.topLayer = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.SliderValue {
                label: "Vertical Gap"
                from: 0
                to: 15
                value: C.Config.settings.bar.verticalGap
                onMoved: C.Config.settings.bar.verticalGap = Math.round(value)
            }

            Spacerr {
            }

            ST.SliderValue {
                label: "Horizontal Gap"
                from: 0
                to: 15
                value: C.Config.settings.bar.horizontalGap
                onMoved: C.Config.settings.bar.horizontalGap = Math.round(value)
            }

            Spacerr {
            }

            ST.SliderValue {
                label: "Height"
                from: 25
                to: 45
                value: C.Config.settings.bar.height
                onMoved: C.Config.settings.bar.height = Math.round(value)
            }

            Spacerr {
            }

            ST.SliderValue {
                label: "Corner radius"
                from: 0
                to: 20
                value: C.Config.settings.bar.radius
                onMoved: C.Config.settings.bar.radius = Math.round(value)
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Modules"

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

            ST.TextValue {
                Layout.fillWidth: true
                implicitHeight: height
                label: "Left"
                value: C.Config.settings.bar.modulesLeft
                onChanged: (x) => {
                    C.Config.settings.bar.modulesLeft = x;
                }
            }

            Spacerr {
            }

            ST.TextValue {
                Layout.fillWidth: true
                implicitHeight: height
                label: "Right"
                value: C.Config.settings.bar.modulesRight
                onChanged: (x) => {
                    C.Config.settings.bar.modulesRight = x;
                }
            }

            Spacerr {
            }

            ST.TextValue {
                Layout.fillWidth: true
                implicitHeight: height
                label: "Center"
                value: C.Config.settings.bar.moduleCenter
                onChanged: (x) => {
                    C.Config.settings.bar.moduleCenter = x;
                }
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Available modules: workspaces, battery, weather, clock, title, mpris, keyboard"

                font {
                    pointSize: C.Config.fontSize.small
                }

            }

            CW.StyledText {
                text: "A module can only be used once. Only one module allowed for center."

                font {
                    pointSize: C.Config.fontSize.small
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
                text: "Workspaces"

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
                label: "Active indicator width"
                from: 1
                to: 4
                value: C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier
                onMoved: C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier = Math.round(value * 10) / 10
                floatVal: true
            }

            Spacerr {
            }

            ST.ChoiceBoxValue {
                label: "Indicator style"
                value: C.Config.settings.bar.workspaces.style
                values: ["Round", "Numbers", "Roman"]
                onMoved: C.Config.settings.bar.workspaces.style = Math.round(value)
            }

            Spacerr {
            }

            ST.SpinBoxValue {
                label: "Workspaces shown"
                from: 1
                to: 15
                value: C.Config.settings.bar.workspaces.shown
                onMoved: C.Config.settings.bar.workspaces.shown = Math.round(value)
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Only current monitor"
                checked: C.Config.settings.bar.workspaces.onlyOnCurrent
                onToggled: C.Config.settings.bar.workspaces.onlyOnCurrent = checked
                Layout.fillWidth: true
            }

            CW.StyledText {
                Layout.topMargin: 20
                text: "Misc"

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

            CW.StyledText {
                Layout.topMargin: 10
                text: "Battery"

                font {
                    pointSize: C.Config.fontSize.h3
                    weight: Font.Medium
                }

            }

            Spacerr {
            }

            ST.SpinBoxValue {
                label: "Low Battery Threshold"
                from: 10
                to: 50
                value: C.Config.settings.bar.battery.low
                onMoved: C.Config.settings.bar.battery.low = Math.round(value)
            }

            Spacerr {
            }

            CW.StyledText {
                Layout.topMargin: 10
                text: "Weather"

                font {
                    pointSize: C.Config.fontSize.h3
                    weight: Font.Medium
                }

            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Enable Weather"
                sublabel: "Uses ipinfo.io and wttr.in"
                checked: C.Config.settings.bar.weather
                onToggled: C.Config.settings.bar.weather = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            ST.TextValue {
                visible: opacity != 0
                opacity: C.Config.settings.bar.weather ? 1 : 0
                Layout.preferredHeight: C.Config.settings.bar.weather ? implicitHeight : 0
                z: C.Config.settings.bar.weather ? 3 : 2
                label: "Override Location"
                value: C.Config.settings.bar.weatherLocation
                onChanged: (x) => {
                    C.Config.settings.bar.weatherLocation = x;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                Layout.preferredHeight: C.Config.settings.bar.weather ? 11 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                visible: opacity != 0
                opacity: C.Config.settings.bar.weather ? 1 : 0
                Layout.preferredHeight: C.Config.settings.bar.weather ? implicitHeight : 0
                Layout.fillWidth: true
                z: C.Config.settings.bar.weather ? 3 : 2
                label: "Don't show location"
                checked: C.Config.settings.bar.weatherNoLocation
                onToggled: C.Config.settings.bar.weatherNoLocation = checked

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                Layout.preferredHeight: C.Config.settings.bar.weather ? 11 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.ValueSwitch {
                visible: opacity != 0
                opacity: C.Config.settings.bar.weather ? 1 : 0
                Layout.preferredHeight: C.Config.settings.bar.weather ? implicitHeight : 0
                Layout.fillWidth: true
                z: C.Config.settings.bar.weather ? 3 : 2
                label: "Use Celcius"
                checked: C.Config.settings.bar.weatherTempInCelcius
                onToggled: C.Config.settings.bar.weatherTempInCelcius = checked

                Behavior on opacity {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            Spacerr {
                Layout.preferredHeight: C.Config.settings.bar.weather ? 11 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
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
