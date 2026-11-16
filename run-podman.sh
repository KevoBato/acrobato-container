#!/bin/sh
# Rootless podman equivalent of compose.yaml (podman has no compose on SteamOS).
#   ACROBATO_DATA / ACROBATO_ROMS / ACROBATO_BIOS as in compose.yaml.
# keep-id maps the host user to the container's abc user (1000), so files in the data
# folder stay owned by you. keep-id also makes that uid the default user, but the image's
# s6 init has to start as (namespaced) root, hence --user 0:0.
set -e
cd "$(dirname "$0")"
DATA="${ACROBATO_DATA:-$PWD/data}"
mkdir -p "$DATA/.local/share/acrobato/roms" "$DATA/.local/share/acrobato/bios"
ROMS="${ACROBATO_ROMS:-$DATA/.local/share/acrobato/roms}"
BIOS="${ACROBATO_BIOS:-$DATA/.local/share/acrobato/bios}"
# Browser gamepads: Selkies' interposer catches open() on /dev/input/event1000-1003, but
# RetroArch (and SDL's fallback) tell pads apart by the node's device number, and a
# rootless container can't mknod. Map four harmless host character devices there, so each
# path has its own number; the interposer means they are never really read. Only as many
# as there are virtual pads (SELKIES_NUM_GAMEPADS, default 1 as in the Dockerfile): a node
# with no pad behind it fails to open, and evmapy (hotkeys) gave up on that.
N="${SELKIES_NUM_GAMEPADS:-1}"
PAD_NODES="" i=0
for dev in /dev/zero /dev/full /dev/random /dev/urandom; do
  [ "$i" -lt "$N" ] || break
  PAD_NODES="$PAD_NODES --device $dev:/dev/input/event$((1000 + i))"
  i=$((i + 1))
done
podman rm -f acrobato >/dev/null 2>&1 || true
exec podman run --rm --name acrobato \
  --userns=keep-id:uid=1000,gid=1000 --user 0:0 \
  -e PUID=1000 -e PGID=1000 -e TZ="${TZ:-Etc/UTC}" \
  -e SELKIES_MANUAL_WIDTH=1280 -e SELKIES_MANUAL_HEIGHT=720 \
  -e SELKIES_NUM_GAMEPADS="$N" \
  -v "$DATA:/config" \
  -v "$ROMS:/config/.local/share/acrobato/roms:ro" \
  -v "$BIOS:/config/.local/share/acrobato/bios:ro" \
  --device /dev/dri:/dev/dri \
  $PAD_NODES \
  -p 3001:3001 --shm-size 1g \
  acrobato:dev
