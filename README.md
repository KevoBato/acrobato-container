# acrobato-container

Runs the [AcroBato](https://github.com/KevoBato/AcroBato) AppImage in a container and streams
it to a web browser, so any computer on the network can play: open
`https://<host>:3001`, accept the self-signed certificate, and plug a controller into that
computer. One shared session: every viewer sees and controls the same screen.

This is a separate project from AcroBato. It takes a released AcroBato AppImage as input
and doesn't change AcroBato's source. Problems found in AcroBato itself are listed in
[ACROBATO-FINDINGS.md](ACROBATO-FINDINGS.md); `patch-appimage.py` works around them in the
image meanwhile.

## How it works

- Base image: LinuxServer.io's `baseimage-selkies:ubuntunoble` (Selkies streaming over
  WebSockets/WebRTC, Xvfb, PulseAudio, nginx, s6). It already has the system libraries the
  AppImage needs (`check-libs.sh` checks).
- The AppImage is extracted to `/opt/acrobato`; `root/defaults/startwm.sh` replaces the
  Selkies desktop with a session D-Bus, openbox, and `acrobato-loop.sh`, which restarts
  AcroBato whenever it exits.
- Browser gamepads come from Selkies' interposer library (`LD_PRELOAD`), which fakes
  `/dev/input/js0-3` and `/dev/input/event1000-1003`.
- The GPU (`/dev/dri`) is passed in for rendering.

## Build

Copy `AcroBato-x86_64.AppImage` into this folder (it isn't in git), then:

```sh
docker build -t acrobato:dev .
```

## Run

**Docker (compose):** set the folders in a `.env` file next to `compose.yaml`, then `docker
compose up -d`.

| Variable | Default | What |
|---|---|---|
| `ACROBATO_DATA` | `./data` | container home: settings, saves, logs, downloaded emulators |
| `ACROBATO_ROMS` | inside `ACROBATO_DATA` | a Batocera-layout roms folder, mounted **read-only** |
| `ACROBATO_BIOS` | inside `ACROBATO_DATA` | bios folder, mounted **read-only** |

Change `:ro` to `:rw` in `compose.yaml` if AcroBato should save gamelists and scraped media
into the roms folder.

**Rootless podman** (for example SteamOS, which has no compose): `./run-podman.sh`, with the
same variables. To keep it running after logging out:

```sh
systemd-run --user --unit acrobato-ctr -E ACROBATO_ROMS=... ./run-podman.sh
systemctl --user stop acrobato-ctr
```

## Host requirements

- x86_64 Linux with Docker or podman.
- A GPU with Mesa drivers (`/dev/dri`) for 3D systems; without it rendering falls back to the
  CPU.
- Nothing else: no FUSE, no `/dev/uinput`, no host input devices are needed.

## Test helpers

- `check-libs.sh`: lists libraries the extracted AppImage needs but the image lacks.
- `launch-test.sh <system>`: run inside the container; launches the first game of a system
  through ES's API on port 1234 and reports whether RetroArch is running.
- `eswatch.sh [seconds]`: run inside the container; waits for EmulationStation to restart and
  prints process snapshots from just before, to see what stopped it.

## License

GPL-3.0-or-later, like AcroBato (see [LICENSE](LICENSE)). The image is built on
LinuxServer.io's Selkies base image and runs AcroBato, each under its own license;
`patch-selkies.py` modifies the bundled Selkies (GPL-3.0) inside the image.
