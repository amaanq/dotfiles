import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

WrapperMouseArea {
  property real topOffset
  property real bottomOffset
  property real leftOffset
  property real extraTopMargin
  property real extraBottomMargin

  topMargin: margin + topOffset + extraTopMargin
  bottomMargin: margin + bottomOffset + extraBottomMargin
  leftMargin: margin + leftOffset

  Layout.fillHeight: true
  Layout.topMargin: -topOffset
  Layout.bottomMargin: -bottomOffset
  Layout.leftMargin: -leftOffset
}
