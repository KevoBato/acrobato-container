#!/bin/sh
# Lists system libraries the extracted AppImage needs but the image lacks.
R=/opt/acrobato
for f in $R/usr/bin/* $R/usr/lib/*.so* $R/usr/lib/libretro/*.so; do
  [ -f "$f" ] && LD_LIBRARY_PATH=$R/usr/lib ldd "$f" 2>/dev/null | grep "not found" | sed "s|^|$(basename $f): |"
done | sort -u
