import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
  id: root

  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: WlrLayer.overlay
  anchors: C.Config.noAnchors
  color: "transparent"
  visible: S.MiscState.shortcutsOpen
  implicitWidth: 1000
  implicitHeight: 600

  GlobalShortcut {
    name: "shortcutsToggle"
    appid: "hyprland-shell"
    description: qsTr("Toggles shortcuts menu on press")

    onPressed: {
      S.MiscState.shortcutsOpen = !S.MiscState.shortcutsOpen
      S.MiscState.shortcutsOpenGrab = S.MiscState.shortcutsOpen
    }
  }

  property list<var> defaultKeybinds: [
    {
      "shortcut": "SUPER + E",
      "description": "Open File Manager"
    },
    {
      "shortcut": "SUPER + Q",
      "description": "Open Terminal"
    },
    {
      "shortcut": "SUPER + R",
      "description": "Open Launcher"
    },
    {
      "shortcut": "SUPER + C",
      "description": "Close window"
    },
    {
      "shortcut": "SUPER + M",
      "description": "Exit Hyprland"
    },
    {
      "shortcut": "SUPER + V",
      "description": "Toggle floating"
    },
    {
      "shortcut": "SUPER + P",
      "description": "Toggle pseudotiling for active window"
    },
    {
      "shortcut": "SUPER + J",
      "description": "Toggle split direction under focus"
    },
    {
      "shortcut": "SUPER + L",
      "description": "Lock the screen"
    },
    {
      "shortcut": "SUPER + F",
      "description": "Fullscreen active window"
    },
    {
      "shortcut": "SUPER + SHIFT + F",
      "description": "Maximize active window"
    },
    {
      "shortcut": "SUPER + Left/Right/Up/Down",
      "description": "Move focus"
    },
    {
      "shortcut": "SUPER + [1-9]",
      "description": "Move to workspace"
    },
    {
      "shortcut": "SUPER + SHIFT + [0-9]",
      "description": "Move current window to workspace"
    },
    {
      "shortcut": "SUPER + S",
      "description": "Toggle special workspace"
    },
    {
      "shortcut": "SUPER + SHIFT + S",
      "description": "Move window to special workspace"
    },
    {
      "shortcut": "SUPER + Scroll",
      "description": "Switch workspaces with scroll"
    },
    {
      "shortcut": "SUPER + LMB",
      "description": "Pick up and move a window with the mouse"
    },
    {
      "shortcut": "SUPER + RMB",
      "description": "Resize window with the mouse"
    },
    {
      "shortcut": "Print Screen",
      "description": "Take a screenshot"
    }
  ]

  HyprlandFocusGrab {
    id: grab

    active: S.MiscState.shortcutsOpenGrab
    windows: [root]
    onCleared: () => {
      S.MiscState.shortcutsOpen = false;
      S.MiscState.shortcutsOpenGrab = false;
    }
  }

  Rectangle {
    id: rectt

    focus: S.MiscState.shortcutsOpenGrab
    Keys.onPressed: event => {
      // Esc to close
      if (event.key === Qt.Key_Escape) {
        S.MiscState.shortcutsOpen = false;
      }
    }

    radius: C.Config.settings.panels.radius
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)
    anchors.fill: parent
    visible: opacity != 0
    opacity: S.MiscState.shortcutsOpen ? 1 : 0

    anchors {
      horizontalCenter: parent.horizontalCenter
      verticalCenter: parent.verticalCenter
    }

    ColumnLayout {
      id: layout

      anchors {
        fill: parent
        margins: 20
      }
      spacing: 10

      anchors {
        left: parent.left
        top: parent.top
        right: parent.right
      }

      CW.StyledText {
        Layout.fillWidth: true
        text: "Shortcuts"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h1
        color: C.Config.theme.primary
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        uniformCellSizes: true

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true

          CW.StyledText {
            id: defaultsTitle
            font {
              pointSize: C.Config.fontSize.h2
              weight: Font.Medium
            }
            text: "Defaults"
          }

          CW.HorizontalLine {
            Layout.leftMargin: 0
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: false
            width: defaultsTitle.width
          }

          ListView {
            id: keybindsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0

            model: root.defaultKeybinds

            delegate: ShortcutBox {
              required property int index
              required property var modelData
              color: index % 2 === 0 ? C.Config.applySecondaryOpacity(C.Config.theme.surface_container_high) : "transparent"
              anchors {
                left: parent.left
                right: parent.right
                rightMargin: defaultListScrollBar.width
              }
              shortcut: modelData.shortcut
              description: modelData.description
            }

            ScrollBar.vertical: CW.StyledScrollBar {
              id: defaultListScrollBar
              anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true

          CW.StyledText {
            id: allTitle
            font {
              pointSize: C.Config.fontSize.h2
              weight: Font.Medium
            }
            text: "All"
          }

          CW.HorizontalLine {
            Layout.leftMargin: 0
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: false
            width: allTitle.width
          }

          ListView {
            id: defaultKeybindsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: S.ShortcutsState.binds
            clip: true
            spacing: 0

            delegate: ShortcutBox {
              required property int index
              required property var modelData
              color: index % 2 === 0 ? C.Config.applySecondaryOpacity(C.Config.theme.surface_container_high) : "transparent"
              anchors {
                left: parent.left
                right: parent.right
                rightMargin: allListScrollBar.width
              }
              property list<string> mods: S.ShortcutsState.modListForMask(modelData.modmask)
              property list<string> notMods: modelData.key.split("&").filter(k => k.trim().length > 0)
              property list<string> keys: [...mods, ...notMods]
              shortcut: `${keys.join(" + ")}`
              description: modelData.has_description ? modelData.description : `${modelData.dispatcher}: ${modelData.arg}`
            }

            ScrollBar.vertical: CW.StyledScrollBar {
              id: allListScrollBar
              anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
              }
            }
          }
        }
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }

  GlobalShortcut {
    name: "keybindsToggle"
    appid: "hyprland-shell"
    description: qsTr("Toggles keybinds page on press")

    onPressed: {
      S.MiscState.shortcutsOpen = !S.MiscState.shortcutsOpen;
      S.MiscState.shortcutsOpenGrab = !S.MiscState.shortcutsOpenGrab;
    }
  }
}
