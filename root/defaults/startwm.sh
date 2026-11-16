#!/usr/bin/env bash
# Replaces the Selkies desktop: a bare window manager (for standalone emulator windows)
# plus AcroBato, restarted whenever it exits.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-abc}"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
exec dbus-launch --exit-with-session /bin/bash /defaults/acrobato-loop.sh
