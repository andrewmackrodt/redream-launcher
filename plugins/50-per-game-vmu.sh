#!/bin/bash

################################################################################
# Script to sanitize rom names to fake support for per-game VMU with redream.
# Rom names should be in TOSEC format and are shortened to lowercase and
# stripped of year / sequel identifier amongst other metadata. This should allow
# games such as Shenmue I and Shenmue II to use the same vmu group to allow
# importing saves across games. This method results in VMUs being shared for
# games which do not support such functionality but hopefully is robust enough
# to prevent vmu0.bin from being filled while attempting to group saves by
# similar titled games, e.g.
#
# bluestinger:
#  Blue Stinger v1.000 (1999)(Activision)(NTSC)(US)[!][%BLUESTINGER]
#
# housedead:
#  House of the Dead 2, The v1.001 (1999)(Sega)(NTSC)(US)[!][13S 51002]
#
# ready2rumbleboxing:
#  Ready 2 Rumble Boxing Round 2 v1.001 (2000)(Midway)(NTSC)(US)(M3)[!]
#  Ready 2 Rumble Boxing v1.000 (1999)(Midway)(NTSC)(US)[!][9I043B T-9704N]
#
# residentevil:
#  Resident Evil - Code Veronica v1.000 (2000)(Capcom)(NTSC)(US)(Disc 1 of 2)[!]
#  Resident Evil - Code Veronica v1.000 (2000)(Capcom)(NTSC)(US)(Disc 2 of 2)[!]
#  Resident Evil 2 v1.001 (2000)(Capcom)(NTSC)(US)(Disc 2 of 2)[!][Claire]
#  Resident Evil 3 - Nemesis v1.000 (2000)(Capcom)(NTSC)(US)[!]
#
# shenmue:
#  Shenmue II v1.001 (2001)(Sega)(PAL)(M4)(Disc 1 of 4)[!]
#  Shenmue II v1.001 (2001)(Sega)(PAL)(M4)(Disc 2 of 4)[!]
#  Shenmue II v1.001 (2001)(Sega)(PAL)(M4)(Disc 3 of 4)[!]
#  Shenmue II v1.001 (2001)(Sega)(PAL)(M4)(Disc 4 of 4)[!]
#  Shenmue v1.001 (2000)(Sega)(PAL)(M4)(Disc 1 of 4)[!]
#  Shenmue v1.001 (2000)(Sega)(PAL)(M4)(Disc 2 of 4)[!]
#  Shenmue v1.001 (2000)(Sega)(PAL)(M4)(Disc 3 of 4)[!]
#  Shenmue v1.001 (2000)(Sega)(PAL)(M4)(Disc 4 of 4)[!][Passport v1.000]
################################################################################

set -o pipefail

if [[ "${REDREAM_DIR:-}" == "" ]] || [[ ! -d "$REDREAM_DIR" ]]; then
  echo "ERROR REDREAM_DIR does not exist: $REDREAM_DIR" >&2
  exit 1
fi

cd "$REDREAM_DIR"

GLOBAL_VMU_RELPATH="vmus/__global"

#region functions
function createVmu() {
  printf '
      \\00
  %.0s' {1..130048} | xxd -r -p
  printf '
      \\fc \\ff
  %.0s' {1..241} | xxd -r -p
  printf '
      \\fa \\ff \\f1 \\00 \\f2 \\00 \\f3 \\00 \\f4 \\00
      \\f5 \\00 \\f6 \\00 \\f7 \\00 \\f8 \\00 \\f9 \\00
      \\fa \\00 \\fb \\00 \\fc \\00 \\fa \\ff \\fa \\ff
  %.0s' {1..1} | xxd -r -p
  printf '
      \\55
  %.0s' {1..16} | xxd -r -p
  printf '
      \\01 \\ff \\ff \\ff \\ff \\00 \\00 \\00 \\00 \\00
      \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00
      \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00
      \\00 \\00 \\19 \\98 \\11 \\27 \\00 \\00 \\58 \\04
      \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\00 \\ff \\00
      \\00 \\00 \\ff \\00 \\fe \\00 \\01 \\00 \\fd \\00
      \\0d \\00 \\00 \\00 \\c8 \\00 \\1f \\00 \\00 \\00
      \\80
  %.0s' {1..1} | xxd -r -p
  printf '
      \\00
  %.0s' {1..425} | xxd -r -p
}

function create_global_vmus() {
  local vmu_relpath
  local link_target

  if [[ ! -d "$GLOBAL_VMU_RELPATH" ]]; then
    mkdir -p "$GLOBAL_VMU_RELPATH"

    if [[ $? -ne 0 ]]; then
      echo "ERROR could not create global vmu directory $GLOBAL_VMU_RELPATH" >&2
      exit 1
    fi
  fi

  for f in vmu0.bin vmu1.bin vmu2.bin vmu3.bin; do
    vmu_relpath="$GLOBAL_VMU_RELPATH/$f"

    if [[ -f "$vmu_relpath" ]]; then
      continue
    fi

    if [[ ! -f "$f" ]]; then
      echo -n "INFO creating global vmu $f .. " >&2

      if createVmu | tee "$vmu_relpath" >/dev/null; then
        echo "OK" >&2
        ln -s "$vmu_relpath" "$f" 2>/dev/null
      else
        echo "ERROR" >&2
      fi
    else
      echo -n "INFO moving $f -> $vmu_relpath .. " >&2

      if [[ ! -L "$f" ]]; then
        if mv "$f" "$vmu_relpath"; then
          echo "OK" >&2
          ln -s "$vmu_relpath" "$f" 2>/dev/null
        else
          echo "ERROR" >&2
        fi
      else
        echo "ERROR" >&2
      fi
    fi
  done
}

function restore_global_vmus() {
  local vmu_relpath
  local link_target

  for f in vmu0.bin vmu1.bin vmu2.bin vmu3.bin; do
    vmu_relpath="$GLOBAL_VMU_RELPATH/$f"
    link_target=$(readlink "$f")

    if [[ "$vmu_relpath" == "$link_target" ]]; then
      continue
    fi

    echo -n "INFO restoring global vmu $f .. " >&2

    if [[ -f "$f" ]] && { [[ ! -L "$f" ]] || [[ ! -f "$vmu_relpath" ]]; } ; then
      echo "ERROR" >&2
      continue
    fi

    if [[ -f "$f" ]]; then
      rm "$f"

      if [[ $? -ne 0 ]]; then
        echo "ERROR" >&2
        continue
      fi
    fi

    ln -s "$vmu_relpath" "$f" && echo "OK" >&2 || echo "ERROR" >&2
  done
}
#endregion

command="$1"
shift

case "$command" in
  start )
    create_global_vmus

    sanitized_name=$(basename "$1" \
      | sed -E 's/\.[A-Za-z0-9]+$//' \
      | sed -E 's/\b(dis[ck]|cd) ?[0-9]+( of [0-9]+)?//ig' \
      | sed -E 's/ ?[\(\[].+//' \
      | sed -E 's/ v[0-9]+(\.[0-9]+)?//' \
      | sed -E 's/ ?[:-] .+//' \
      | sed -E 's/[^A-Za-z0-9 -]//g' \
      | sed -E 's/ ?\b[IVX]+\b//g' \
      | sed -E 's/ (Col(lection)?|Hits|Round|Ver(sion)?|Vol(ume)?)\.?//ig' \
      | sed -E 's/([0-9])[Kk]([0-9]+)/\100\2/g' \
      | sed -E 's/([0-9])[Kk]\b/\1000/g' \
      | sed -E 's/\b(a|as|in|of|on|the|dreamcast)\b//ig' \
      | sed -E 's/  +/ /g' \
      | sed -E 's/ [0-9]+([A-Za-z0-9]*)? *$//' \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]//g' )

    if [[ "$sanitized_name" != "" ]]; then
      game_vmu_relpath="vmus/$sanitized_name"

      # create directory for game specific vmu files
      if [[ ! -d "$game_vmu_relpath" ]]; then
        mkdir -p "$game_vmu_relpath"

        if [[ $? -ne 0 ]]; then
          echo "ERROR could not create game vmu directory: $game_vmu_relpath" >&2
          exit 1
        fi
      fi

      # create symlinks to game specific vmu in redream directory
      for f in vmu0.bin vmu1.bin vmu2.bin vmu3.bin; do
        game_vmu_device_relpath="$game_vmu_relpath/$f"

        # create empty vmu file
        if [[ ! -f "$game_vmu_device_relpath" ]]; then
          createVmu | tee "$game_vmu_device_relpath" >/dev/null

          if [[ $? -ne 0 ]]; then
            echo "WARN failed to create vmu file: $game_vmu_device_relpath" >&2
            continue
          fi
        fi

        if [[ -L "$f" ]]; then
          # remove vmu symlinks in redream directory if link to different path
          link_target=$(readlink "$f")

          if [[ "$link_target" != "$game_vmu_device_relpath" ]]; then
            if ! rm "$f"; then
              echo "ERROR failed to remove existing vmu link $f -> $link_target" >&2
              continue
            fi
          fi
        fi

        # create game vmu symlink in redream directory
        if [[ ! -L "$f" ]]; then
          echo -n "INFO creating vmu link $f -> $game_vmu_device_relpath .. " >&2
          ln -s "$game_vmu_device_relpath" "$f" && echo "OK" >&2
        fi
      done
    else
      restore_global_vmus
    fi
    ;;
  stop )
    restore_global_vmus
    ;;
esac
