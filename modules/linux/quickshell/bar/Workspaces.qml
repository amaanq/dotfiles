import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../config" as C
import "../commonwidgets" as CW

OffsetMouseWrapper {
  id: root

  property real padding: height / 4
  property real topInset: 0
  property real bottomInset: 0

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
  property int shownWorkspaces: C.Config.settings.bar.workspaces.shown
  property int baseWorkspace: Math.floor((activeWorkspace - 1) / shownWorkspaces) * shownWorkspaces + 1

  // trackpads
  property int scrollAccumulator: 0

  function colorForWorkspace(ws) {
    if (ws.monitor == root.monitor)
      return ws.active ? C.Config.theme.primary : Qt.darker(C.Config.theme.primary, 1.5);
    else
      return ws.active ? C.Config.theme.secondary : Qt.darker(C.Config.theme.secondary, 1.5);
  }

  acceptedButtons: Qt.NoButton
  onWheel: event => {
    event.accepted = true;
    let acc = scrollAccumulator - event.angleDelta.x - event.angleDelta.y;
    const sign = Math.sign(acc);
    acc = Math.abs(acc);

    const offset = sign * Math.floor(acc / 120);
    scrollAccumulator = sign * (acc % 120);

    if (offset != 0) {
      const currentWorkspace = root.activeWorkspace;
      const targetWorkspace = currentWorkspace + offset;
      const id = Math.max(baseWorkspace, Math.min(baseWorkspace + shownWorkspaces - 1, targetWorkspace));
      if (id != currentWorkspace)
        Hyprland.dispatch(`workspace ${id}`);
    }
  }

  Row {
    spacing: 1

    Repeater {
      model: ScriptModel {
        objectProp: "index"
        values: {
          const workspaces = Hyprland.workspaces.values;
          const base = root.baseWorkspace;
          let arr = Array.from({
            length: root.shownWorkspaces
          }, (_, i) => ({
                index: base + i,
                workspace: workspaces.find(w => w.id == base + i)
              }));

          if (C.Config.settings.bar.workspaces.onlyOnCurrent)
            arr = arr.filter(x => {
              return x.workspace && x.workspace.monitor && x.workspace.monitor == root.monitor;
            });
          return arr;
        }
      }

      WrapperMouseArea {
        id: delegate
        required property var modelData

        implicitHeight: parent.height
        leftMargin: 1
        rightMargin: 1
        topMargin: root.topInset + root.padding
        bottomMargin: root.bottomInset + root.padding

        onPressed: Hyprland.dispatch(`workspace ${modelData.index}`)

        Rectangle {
          property real activeMul: C.Config.settings.bar.workspaces.style == 0 ? (delegate.modelData.workspace?.active ?? false ? (C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier) : 1) : 1
          Behavior on activeMul {
            NumberAnimation {
              duration: C.Globals.anim_SLOW
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }

          radius: height / 2
          implicitWidth: C.Config.settings.bar.workspaces.style != 0 ? text.implicitWidth + 2 : height * activeMul

          color: C.Config.settings.bar.workspaces.style != 0 ? "transparent" : (delegate.modelData.workspace ? colorForWorkspace(delegate.modelData.workspace) : C.Config.theme.surface_container_highest)

          Behavior on color {
            ColorAnimation {
              duration: C.Globals.anim_SLOW
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }

          CW.StyledText {
            id: text
            visible: C.Config.settings.bar.workspaces.style != 0
            text: C.Config.settings.bar.workspaces.style == 1 ? "" + modelData.index : C.Config.romanize(modelData.index)
            anchors {
              top: parent.top
              bottom: parent.bottom
            }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: C.Config.settings.bar.workspaces.style == 2 ? C.Config.fontSize.small : C.Config.fontSize.normal
            color: (delegate.modelData.workspace ? colorForWorkspace(delegate.modelData.workspace) : C.Config.theme.surface_container_highest)

            Behavior on color {
              ColorAnimation {
                duration: C.Globals.anim_SLOW
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }
          }
        }
      }
    }
  }
}
