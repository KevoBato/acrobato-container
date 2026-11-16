#!/usr/bin/env bash
# Runs inside the session D-Bus started by startwm.sh.

# SDL minimizes a fullscreen window when it loses focus, so ES iconifies itself as soon
# as a game's window opens. On a desktop the user (or the session) restores it; on the
# container's virtual display nothing does and the stream stays black after the game.
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0

# Only the window in front reads the controller. Otherwise an ES left behind a running
# game (for example after it restarted) navigates and launches games from the same button
# presses. Environment variables override SDL hints an app sets at normal priority.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=0

openbox >/dev/null 2>&1 &
while true; do
  /opt/acrobato/AppRun >>"$HOME/acrobato-es.log" 2>&1
  sleep 2
done
