#!/usr/bin/env nu

# Migrate your_spotify (MongoDB) listening data into spotrak (PostgreSQL).
#
# Seeds the spotrak catalog (artists/albums/tracks) and listening_events from
# the live your_spotify Mongo, tagging events source='seed'. spotrak's
# (user, track, 30s-bucket) unique index means a later native import of the
# Spotify "Extended Streaming History" export dedups against this automatically,
# so the two sources reconcile without manual conflict handling.
#
# Requires `mongoexport` (mongodb-tools) and `psql` on PATH.
#
# FK-sensitive rows (tracks, *_artists, events) are staged into TEMP tables and
# filtered with EXISTS in Postgres, so orphan references in old Mongo data are
# dropped cleanly instead of aborting the load on a foreign-key violation.

# Render a scalar as a SQL literal, doubling single quotes. NULL when missing.
def sql-str [v: any]: nothing -> string {
  if $v == null {
    "NULL"
  } else {
    let s = $v | into string | str replace --all "'" "''"
    $"'($s)'"
  }
}

def sql-int [v: any]: nothing -> string {
  if $v == null { "NULL" } else { try { $v | into int | into string } catch { "NULL" } }
}

def sql-bool [v: any]: nothing -> string {
  if $v == null { "NULL" } else if $v { "TRUE" } else { "FALSE" }
}

# Render a list/record as a jsonb literal; empty array fallback when null.
def sql-jsonb [v: any]: nothing -> string {
  let val = $v | default []
  let j = $val | to json --raw | str replace --all "'" "''"
  $"'($j)'::jsonb"
}

# Mongo dates come through extended JSON as {"$date": "<iso>"} (relaxed) or
# {"$date": {"$numberLong": "<ms>"}} (canonical). Produce a SQL timestamptz.
def sql-ts [v: any]: nothing -> string {
  if $v == null {
    "NULL"
  } else {
    let d = if ($v | describe | str starts-with "record") { $v | get --optional '$date' } else { $v }
    if ($d | describe | str starts-with "record") {
      let ms = $d | get --optional '$numberLong' | default 0 | into int
      $"to_timestamp\(($ms) / 1000.0\)"
    } else {
      (sql-str $d) + "::timestamptz"
    }
  }
}

# Export one Mongo collection as a list of records.
def export-collection [
  uri: string
  db: string
  collection: string
]: nothing -> list {
  let res = (
    ^mongoexport --uri $uri --db $db --collection $collection --jsonArray --jsonFormat relaxed
      | complete
  )
  if $res.exit_code != 0 {
    error make { msg: $"mongoexport ($collection) failed: ($res.stderr)" }
  }
  $res.stdout | from json
}

# Build a multi-row "INSERT ... VALUES (..),(..) <suffix>;" statement, or "" when
# there are no rows. `rows` is a list of already-rendered "(...)" value strings.
def insert-stmt [table: string, columns: string, rows: list<string>, suffix: string]: nothing -> string {
  if ($rows | is-empty) {
    ""
  } else {
    let values = $rows | str join ",\n"
    $"INSERT INTO ($table) \(($columns)\) VALUES\n($values)\n($suffix);\n"
  }
}

def main [
  --database-url: string                       # postgres connection string (required)
  --mongo-uri: string = "mongodb://localhost:27017"
  --mongo-db: string = "your_spotify"
  --dry-run                                     # export + transform + report, no writes
] {
  if $database_url == null and not $dry_run {
    error make { msg: "--database-url is required (or pass --dry-run)" }
  }

  print "exporting collections from mongo..."
  let users = export-collection $mongo_uri $mongo_db "users"
  let artists = export-collection $mongo_uri $mongo_db "artists"
  let albums = export-collection $mongo_uri $mongo_db "albums"
  let tracks = export-collection $mongo_uri $mongo_db "tracks"
  let infos = export-collection $mongo_uri $mongo_db "infos"

  print $"  users: ($users | length), artists: ($artists | length), albums: ($albums | length), tracks: ($tracks | length), events: ($infos | length)"

  let user = $users | where spotifyId != null | first
  if $user == null {
    error make { msg: "no user with a spotifyId found in mongo" }
  }
  print $"migrating user: ($user.username) \(($user.spotifyId)\)"

  # --- artists: no outgoing FKs, insert directly ---------------------------
  let artist_rows = $artists | each {|a|
    $"\((sql-str $a.id), (sql-str $a.name?), (sql-str $a.href?), (sql-str $a.uri?), (sql-str $a.type?), (sql-jsonb $a.images?), (sql-jsonb $a.genres?)\)"
  }
  let sql_artists = insert-stmt "artists" "id, name, href, uri, type, images, genres" $artist_rows "ON CONFLICT (id) DO NOTHING"

  # --- albums: no outgoing FKs, insert directly ----------------------------
  let album_rows = $albums | each {|a|
    let year = $a.release_date? | default "" | str substring 0..4
    let year_sql = if ($year | str length) == 4 { sql-int $year } else { "NULL" }
    $"\((sql-str $a.id), (sql-str $a.name?), (sql-str $a.album_type?), (sql-str $a.release_date?), (sql-str $a.release_date_precision?), ($year_sql), (sql-str $a.href?), (sql-str $a.uri?), (sql-str $a.type?), (sql-jsonb $a.images?)\)"
  }
  let sql_albums = insert-stmt "albums" "id, name, album_type, release_date, release_date_precision, release_year, href, uri, type, images" $album_rows "ON CONFLICT (id) DO NOTHING"

  # --- album_artists: stage then filter on existing album + artist ---------
  let aa_rows = $albums | each {|a|
    $a.artists? | default [] | enumerate | each {|e|
      $"\((sql-str $a.id), (sql-str $e.item), ($e.index))"
    }
  } | flatten

  # --- tracks: stage then filter on existing album -------------------------
  let track_rows = $tracks | each {|t|
    $"\((sql-str $t.id), (sql-str $t.name?), (sql-str $t.album?), (sql-int $t.duration_ms?), (sql-bool $t.explicit?), (sql-str $t.href?), (sql-str $t.uri?), (sql-str $t.type?), (sql-int $t.disc_number?), (sql-int $t.track_number?)\)"
  }

  # --- track_artists: stage then filter on existing track + artist ---------
  let ta_rows = $tracks | each {|t|
    $t.artists? | default [] | enumerate | each {|e|
      $"\((sql-str $t.id), (sql-str $e.item), ($e.index))"
    }
  } | flatten

  # --- listening_events: stage then filter on existing track/album/artist --
  let event_rows = $infos | each {|i|
    let bl = if (($i.blacklistedBy? | default [] | length) > 0) { "'artist'" } else { "NULL" }
    $"\((sql-str $i.id), (sql-str $i.albumId?), (sql-str $i.primaryArtistId?), (sql-int $i.durationMs?), (sql-ts $i.played_at?), ($bl)\)"
  }

  if $dry_run {
    print "dry run; no writes. rendered row counts:"
    print $"  artists=($artist_rows | length) albums=($album_rows | length) album_artists=($aa_rows | length) tracks=($track_rows | length) track_artists=($ta_rows | length) events=($event_rows | length)"
    return
  }

  # Insert (or reuse) the spotrak user, returning its UUID for the events.
  let user_sql = $"INSERT INTO users \(username, spotify_id, admin, first_listened_at\) VALUES \((sql-str $user.username), (sql-str $user.spotifyId), TRUE, (sql-ts $user.firstListenedAt?)\) ON CONFLICT \(spotify_id\) DO UPDATE SET username = EXCLUDED.username RETURNING id;"
  let user_id = (
    $user_sql | ^psql $database_url --no-align --tuples-only --quiet -v ON_ERROR_STOP=1 | complete
  )
  if $user_id.exit_code != 0 {
    error make { msg: $"failed to upsert user: ($user_id.stderr)" }
  }
  let uid = $user_id.stdout | str trim
  print $"spotrak user id: ($uid)"

  # One transactional session: direct catalog inserts, then FK-filtered loads
  # of tracks / *_artists / events via TEMP staging tables.
  let script = [
    "BEGIN;"
    $sql_artists
    $sql_albums

    "CREATE TEMP TABLE stage_aa (album_id text, artist_id text, position int) ON COMMIT DROP;"
    (insert-stmt "stage_aa" "album_id, artist_id, position" $aa_rows "")
    "INSERT INTO album_artists (album_id, artist_id, position) SELECT album_id, artist_id, position FROM stage_aa s WHERE EXISTS (SELECT 1 FROM albums WHERE id = s.album_id) AND EXISTS (SELECT 1 FROM artists WHERE id = s.artist_id) ON CONFLICT (album_id, artist_id) DO NOTHING;"

    "CREATE TEMP TABLE stage_tracks (id text, name text, album_id text, duration_ms int, explicit bool, href text, uri text, type text, disc_number int, track_number int) ON COMMIT DROP;"
    (insert-stmt "stage_tracks" "id, name, album_id, duration_ms, explicit, href, uri, type, disc_number, track_number" $track_rows "")
    "INSERT INTO tracks (id, name, album_id, duration_ms, explicit, href, uri, type, disc_number, track_number) SELECT id, name, album_id, COALESCE(duration_ms, 0), COALESCE(explicit, FALSE), href, uri, type, disc_number, track_number FROM stage_tracks s WHERE EXISTS (SELECT 1 FROM albums WHERE id = s.album_id) ON CONFLICT (id) DO NOTHING;"

    "CREATE TEMP TABLE stage_ta (track_id text, artist_id text, position int) ON COMMIT DROP;"
    (insert-stmt "stage_ta" "track_id, artist_id, position" $ta_rows "")
    "INSERT INTO track_artists (track_id, artist_id, position) SELECT track_id, artist_id, position FROM stage_ta s WHERE EXISTS (SELECT 1 FROM tracks WHERE id = s.track_id) AND EXISTS (SELECT 1 FROM artists WHERE id = s.artist_id) ON CONFLICT (track_id, artist_id) DO NOTHING;"

    "CREATE TEMP TABLE stage_events (track_id text, album_id text, primary_artist_id text, duration_ms int, played_at timestamptz, blacklisted_by text) ON COMMIT DROP;"
    (insert-stmt "stage_events" "track_id, album_id, primary_artist_id, duration_ms, played_at, blacklisted_by" $event_rows "")
    $"INSERT INTO listening_events \(user_id, track_id, album_id, primary_artist_id, duration_ms, played_at, source, blacklisted_by\) SELECT '($uid)', track_id, album_id, primary_artist_id, COALESCE\(duration_ms, 0\), played_at, 'seed', blacklisted_by FROM stage_events s WHERE played_at IS NOT NULL AND EXISTS \(SELECT 1 FROM tracks WHERE id = s.track_id\) AND EXISTS \(SELECT 1 FROM albums WHERE id = s.album_id\) AND EXISTS \(SELECT 1 FROM artists WHERE id = s.primary_artist_id\) ON CONFLICT DO NOTHING;"

    "COMMIT;"
  ] | str join "\n"

  print "loading into postgres..."
  let res = ($script | ^psql $database_url --quiet -v ON_ERROR_STOP=1 | complete)
  if $res.exit_code != 0 {
    error make { msg: $"psql load failed: ($res.stderr)" }
  }
  print "done. verify with: psql <url> -c 'SELECT count(*) FROM listening_events;'"
}
