# AcroBato, streamed to a web browser (Selkies / WebRTC).
# Build context must contain AcroBato-x86_64.AppImage (copy it in; it is not in git).
FROM lscr.io/linuxserver/baseimage-selkies:ubuntunoble

# Libraries that downloaded emulators need beyond what AcroBato itself uses:
#   libxcb-cursor0: Qt 6's xcb platform plugin (Eglantine; most Qt-based emulators)
RUN apt-get update \
 && apt-get install -y --no-install-recommends libxcb-cursor0 \
 && rm -rf /var/lib/apt/lists/*

# Selkies' gamepad server froze every virtual pad when one client stopped reading.
COPY patch-selkies.py /tmp/
RUN python3 -I /tmp/patch-selkies.py /lsiopy/lib/python3.12/site-packages/selkies/input_handler.py \
 && rm /tmp/patch-selkies.py

ARG APPIMAGE=AcroBato-x86_64.AppImage
COPY ${APPIMAGE} /tmp/acrobato.AppImage
RUN cd /opt \
 && chmod +x /tmp/acrobato.AppImage \
 && /tmp/acrobato.AppImage --appimage-extract >/dev/null \
 && mv squashfs-root acrobato \
 && chmod -R go+rX acrobato \
 && rm /tmp/acrobato.AppImage

# Container fixes not yet in the AppImage (see the script): hotkeygen without /dev/uinput
# or with host devices it can't open, and Content Downloader installs with read-only roms.
COPY patch-appimage.py /tmp/
RUN /opt/acrobato/usr/python/bin/python3 -I /tmp/patch-appimage.py /opt/acrobato \
 && rm /tmp/patch-appimage.py

COPY root/ /
RUN chmod +x /defaults/startwm.sh /defaults/acrobato-loop.sh /custom-cont-init.d/*

ENV TITLE=AcroBato
# Virtual controllers offered to the browser (1-4). Each one is a connected controller to
# every game, so 1 unless more players will join (see patch-selkies.py).
ENV SELKIES_NUM_GAMEPADS=1
