# Findings for AcroBato (from the container project)

Running AcroBato in a container (this project) turned up bugs in AcroBato itself. They're
**not** changed in the AcroBato repo; this project works around them by patching the
extracted AppImage (`patch-appimage.py`) or the container setup. A future AcroBato agent may
want to fix them at the source. Found 2026-11-15, against the AcroBato build whose AppImage
sha256 starts `707ebd7c5872ae8e`.

Each item: what happens, why, and the fix that was tested here.

## 1. hotkeygen crashes when `/dev/uinput` doesn't exist (every game launch fails)

- **Seen on:** a host whose kernel has no uinput at all (ZimaOS: `CONFIG_INPUT_UINPUT` not
  set). Could also happen on other minimal or locked-down systems and in any container.
- **What happens:** every game goes back to ES after a few seconds. `es_launch_stderr.log`
  ends in `DBusError: The name org.batocera.Hotkeygen was not provided by any .service files`.
- **Why:** AcroBato's existing desktop tweak in `scripts/relocate-launcher.py` wraps
  `evdev.UInput(...)` in hotkeygen's `daemon.py` with `except OSError`. That covers "no
  permission", but a **missing** device raises `evdev.UInputError`, which is not an
  `OSError`. hotkeygen dies, and the launcher can't reach it over D-Bus.
- **Fix tested:** `except (OSError, evdev.UInputError) as e:` in that tweak. (evmapy already
  catches `UInputError` and is fine.)

## 2. hotkeygen crashes on input devices listed in `/sys` but not openable

- **Seen on:** podman/Docker containers (the container sees the host's `/sys/class/input`,
  but not its `/dev/input` nodes). Possibly also on hosts with odd permissions or races at
  hot-unplug.
- **What happens:** hotkeygen exits with `FileNotFoundError: ... '/dev/input/event12'` from
  `_get_input_device_mapping` → `get_input_device` → `evdev.InputDevice`. Same effect as #1.
- **Fix tested:** in hotkeygen `daemon.py`, `__add_udev_device`, wrap
  `_get_input_device_mapping(device, self.debug)` in `try/except OSError` and skip the
  device (`return`). Would go in `relocate-launcher.py` as another hotkeygen tweak.

## 3. Content Downloader: a read-only roms folder fails the whole install

- **Where:** `packaging/store/acrobato_store.py`, end of `cmd_install`.
- **What happens:** the emulator downloads and installs, then writing
  `roms/<system>/Open <Name>.emuapp` raises `Read-only file system`, and ES shows an error,
  as if the install failed (the state file and launcher were already written).
- **When:** the roms folder is a shared library mounted read-only (as this project does), or
  on a read-only network share.
- **Fix tested:** those entries are optional: skip if the file exists, and catch `OSError`
  around `mkdir` + `write_text`, printing a warning to stderr.

## 4. Downloaded AppImages: FUSE check only looks for `fusermount`

- **Where:** the launcher text `install_appimage` writes in `acrobato_store.py`.
- **What happens:** it uses `APPIMAGE_EXTRACT_AND_RUN=1` only when neither `fusermount3` nor
  `fusermount` exists. A container (or a system without the fuse module loaded) can have the
  tools but no usable `/dev/fuse`, so the AppImage tries to mount and fails.
- **Fix tested:** `if [ ! -w /dev/fuse ] || { ! command -v fusermount3 ... && ! command -v
  fusermount ...; }; then export APPIMAGE_EXTRACT_AND_RUN=1; fi`. Only affects launchers
  written after the change; existing ones keep the old check until reinstalled.

## 5. ES stays minimized after a game (black screen) when nothing restores it

- **Seen on:** the container's virtual display (Xvfb + openbox). Likely also under other
  minimal window managers or kiosk sessions.
- **Why:** SDL minimizes a fullscreen window when it loses focus
  (`SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS`, on by default). ES goes Iconic as soon as the
  game's window opens; after the game, its restore request isn't honored and ES stays hidden.
  ES's `HideWindow` setting is **not** the cause (setting it to false didn't help).
- **Workaround here:** `SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0` in the environment ES starts in.
- **Possible AppImage change:** AppRun could export that variable for ES. Check first that it
  doesn't hurt desktop and Steam Game Mode use (it shouldn't: ES is meant to stay behind the
  game anyway).

## 6. Minor, noticed in passing

- AppRun links Dolphin `Sys` and PPSSPP assets into `bios/` (`link_data`). With a read-only
  bios folder the `ln` fails (logged, harmless otherwise), so GameCube/PSP may lack those
  files. Linking them somewhere AcroBato owns (or pointing the emulators at the AppDir copy)
  would avoid depending on a writable bios folder.
- Selkies' virtual pads report GUID `00000000000000000000000000000000` to ES; mapping still
  works via the name ("Microsoft X-Box 360 pad" in `es_input-extra.cfg`). Worth knowing if
  GUID-based matching ever becomes stricter.
- `nice: cannot set niceness: Permission denied` appears when emulators start in a
  container; harmless.
