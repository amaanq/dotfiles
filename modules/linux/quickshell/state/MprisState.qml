pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import "../config" as C

Singleton {
  id: root

  property MprisPlayer player: null
  property MprisPlayer lastChangedPlayer: null
  property var changedPlayers: new Set()

  function playerIsValidForMpris(p) {
    let hasAny = (arr, what) => {
      for (let w of what) {
        if (arr.indexOf(w) != -1)
          return true;
      }
      return false;
    };

    let dbusName = p.dbusName.split('.');
    if (dbusName[dbusName.length - 1].indexOf("nstance") != -1)
      dbusName = dbusName[dbusName.length - 2]
    else
      dbusName = dbusName[dbusName.length - 1]

    if (C.Config.settings.mpris.selectionMode == 0 && hasAny(C.Config.settings.mpris.excludedPlayers, [p.identity, p.dbusName, p.desktopEntry, dbusName]))
      return false;

    if (C.Config.settings.mpris.selectionMode == 1 && !hasAny(C.Config.settings.mpris.includedPlayers, [p.identity, p.dbusName, p.desktopEntry, dbusName]))
      return false;

    return true;
  }

  function updatePlayer() {
    let leader = null;
    let backup = lastChangedPlayer;
    for (let p of Mpris.players.values) {
      if (!playerIsValidForMpris(p))
        continue;

      if (p.isPlaying) {
        backup = p;
        if (p.trackArtist != "")
          leader = p;
      }
    }

    if (lastChangedPlayer != null) {
      if (!playerIsValidForMpris(lastChangedPlayer)) {
        lastChangedPlayer = null;
        backup = null;
      }
    }

    player = leader != null ? leader : backup;
  }

  function handlePlayerChanged(player: MprisPlayer) {
    if (!player.isPlaying)
      return;

    changedPlayers.delete(player);

    if (!playerIsValidForMpris(player))
      return;

    changedPlayers.add(player);
    lastChangedPlayer = player ?? null;

    updatePlayer();
  }

  function playerDestroyed(player: MprisPlayer) {
    changedPlayers.delete(player);

    if (!playerIsValidForMpris(player))
      return;

    lastChangedPlayer = changedPlayers[changedPlayers.size] ?? null;

    updatePlayer();
  }

  Instantiator {
    model: Mpris.players

    Connections {
      required property MprisPlayer modelData
      target: modelData

      Component.onCompleted: root.handlePlayerChanged(modelData)
      Component.onDestruction: root.playerDestroyed(modelData)

      function onPlaybackStateChanged() {
        root.handlePlayerChanged(modelData);
      }
    }
  }

  IpcHandler {
    target: "mpris"

    function pauseAll() {
      for (const player of Mpris.players.values) {
        if (player.canPause)
          player.pause();
      }
    }

    function togglePlaying() {
      const player = root.player;
      if (player && player.canTogglePlaying)
        player.togglePlaying();
    }

    function previous() {
      const player = root.player;
      if (player && player.canGoPrevious)
        player.previous();
    }

    function next() {
      const player = root.player;
      if (player && player.canGoNext)
        player.next();
    }
  }
}
