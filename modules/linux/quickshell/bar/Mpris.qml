import QtQuick
import QtQuick.Layouts
import "../state" as S
import "../commonwidgets" as CW

BarButton {
  id: root
  visible: S.MprisState.player

  acceptedButtons: Qt.LeftButton | Qt.BackButton | Qt.ForwardButton

  onPressed: event => {
    const player = S.MprisState.player;
    if (!player)
      return;

    if (event.button == Qt.LeftButton) {
      if (player.canTogglePlaying)
        player.togglePlaying();
    } else if (event.button == Qt.BackButton) {
      if (player.canGoPrevious)
        player.previous();
    } else if (event.button == Qt.ForwardButton) {
      if (player.canGoNext)
        player.next();
    }
  }

  leftPadding: 7
  rightPadding: leftPadding

  RowLayout {
    CW.FontIcon {
      text: (S.MprisState.player?.isPlaying ?? false) ? "pause" : "play_arrow"
    }

    CW.StyledText {
      Layout.fillWidth: true
      text: (S.MprisState.player?.trackArtist ?? "") + (" – ") + (S.MprisState.player?.trackTitle ?? "")
      elide: Text.ElideRight
    }
  }
}
