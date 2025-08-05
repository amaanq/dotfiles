import "../../commonwidgets" as CW
import "../../config" as C
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Item {
  id: root

  property string overrideIcon: ""
  property bool isDefault: false
  property bool isMuted: false
  property bool canBeDefault: false

  required property PwNode node
  PwObjectTracker {
    objects: [node]
  }

  implicitHeight: contentLayout.implicitHeight
  RowLayout {
    id: contentLayout
    anchors.fill: parent

    Image {
      property real size: 20
      visible: source != "speaker"
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      sourceSize.width: size
      sourceSize.height: size
      width: size
      height: size
      source: {
        let icon;
        if (root.overrideIcon != "")
          return Quickshell.iconPath(root.overrideIcon, "speaker");

        icon = root.node.properties["application.icon-name"];
        if (Quickshell.iconPath(icon, "speaker") !== "speaker")
          return Quickshell.iconPath(icon, "speaker");
        icon = root.node.properties["node.name"];
        return Quickshell.iconPath(icon, "speaker");
      }
    }

    ColumnLayout {
      id: columnLayout
      RowLayout {
        Layout.fillWidth: true
        CW.StyledText {
          Layout.fillWidth: true
          elide: Text.ElideRight
          text: {
            const app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
            const media = root.node.properties["media.name"];
            return media != undefined ? `${app} • ${media}` : app;
          }
        }
        WrapperMouseArea {
          id: muteMa
          hoverEnabled: true
          visible: node.id > 0

          onPressed: {
            if (node.id < 1)
              return;

            console.log("toggling mute of " + node.id + " with wpctl");

            Quickshell.execDetached(["wpctl", "set-mute", node.id + "", "toggle"])
          }

          Rectangle {
            implicitWidth: 15
            implicitHeight: 15

            radius: 4
            color: isMuted ? (muteMa.containsMouse ? Qt.lighter(C.Config.theme.primary, 1.1) : C.Config.theme.primary) : C.Config.applySecondaryOpacity(muteMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)

            CW.FontIcon {
              text: isMuted ? "volume_off" : "volume_up"
              anchors.centerIn: parent
              transform: Scale { xScale: 0.8; yScale: 0.8; origin.x: 15 / 2; origin.y: 15 / 2; }
              color: isMuted ? C.Config.theme.surface_container_high : C.Config.theme.on_surface

              Behavior on color {
                ColorAnimation {
                  duration: 400
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                }
              }
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
          id: defaultMa
          visible: canBeDefault
          hoverEnabled: true

          onPressed: {
            if (isDefault || node.id < 1)
              return;

            console.log("changing default sink to " + node.id + " with wpctl");

            Quickshell.execDetached(["wpctl", "set-default", node.id + ""])
          }

          Rectangle {
            implicitWidth: 15
            implicitHeight: 15

            radius: 4
            color: isDefault ? (defaultMa.containsMouse ? Qt.lighter(C.Config.theme.primary, 1.1) : C.Config.theme.primary) : C.Config.applySecondaryOpacity(defaultMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)

            CW.FontIcon {
              text: "check_small"
              anchors.centerIn: parent
              color: isDefault ? C.Config.theme.surface_container_high : C.Config.theme.on_surface
              transform: Scale { xScale: 0.9; yScale: 0.9; origin.x: 15 / 2; origin.y: 15 / 2; }

              Behavior on color {
                ColorAnimation {
                  duration: 400
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                }
              }
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
        CW.StyledText {
          text: `${Math.round((root.node.audio?.volume ?? 0) * 100)}%`
        }
      }
      RowLayout {
        CW.StyledSlider {
          id: slider
          Layout.fillWidth: true
          value: root.node.audio?.volume ?? 0
          onValueChanged: root.node.audio.volume = value
        }
      }
    }
  }
}
