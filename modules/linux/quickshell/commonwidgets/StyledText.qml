import QtQuick
import QtQuick.Layouts
import "../config" as C

Text {
  renderType: C.Config.settings.fonts.useNativeRendering ? Text.NativeRendering : Text.QtRendering
  verticalAlignment: Text.AlignVCenter
  font {
    hintingPreference: Font.PreferFullHinting
    pointSize: C.Config.fontSize.normal
  }
  color: C.Config.theme.on_surface
  linkColor: C.Config.theme.primary_fixed
}
