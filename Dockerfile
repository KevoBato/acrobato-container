# AcroBato, streamed to a web browser (Selkies / WebRTC).
# Build context must contain AcroBato-x86_64.AppImage (copy it in; it is not in git).
FROM lscr.io/linuxserver/baseimage-selkies:ubuntunoble

# Libraries that downloaded emulators need beyond what AcroBato itself uses:
#   libxcb-cursor0: Qt 6's xcb platform plugin (Eglantine; most Qt-based emulators)
RUN apt-get update \
 && apt-get install -y --no-install-recommends libxcb-cursor0 \
 && rm -rf /var/lib/apt/lists/*

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
