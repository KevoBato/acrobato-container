"""Applies container fixes to the extracted AcroBato AppImage (argv[1]). They are proposed
to AcroBato itself in ACROBATO-FINDINGS.md; once an AppImage carries them, each patch here
is skipped (already present). A patch whose original text is gone fails the build, so a
changed upstream file is noticed instead of silently left unpatched."""
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
SITE = 'usr/python/lib/python3.14/site-packages'

PATCHES = {
    f'{SITE}/hotkeygen/daemon.py': [
        # No /dev/uinput at all raises UInputError, not OSError.
        ('        except OSError as e:\n'
         "            print(f'no virtual keyboard",
         '        except (OSError, evdev.UInputError) as e:\n'
         "            print(f'no virtual keyboard"),
        # sysfs lists the host's input devices, but their /dev nodes aren't in the container.
        ('        input_device_mapping = _get_input_device_mapping(device, self.debug)\n',
         '        try:\n'
         '            input_device_mapping = _get_input_device_mapping(device, self.debug)\n'
         '        except OSError as e:\n'
         "            print(f'skipping {device.device_node}: {e}')\n"
         '            return\n'),
    ],
    'usr/share/acrobato/acrobato_store.py': [
        # "Open <emulator>" entries are optional; the roms folder may be mounted read-only.
        ('    for f in window_entries(e):\n'
         '        f.parent.mkdir(parents=True, exist_ok=True)\n'
         "        f.write_text(e['id'] + '\\n')\n",
         '    for f in window_entries(e):\n'
         '        if f.exists():\n'
         '            continue\n'
         '        try:  # optional: the roms folder may be read-only (e.g. a shared library in Docker)\n'
         '            f.parent.mkdir(parents=True, exist_ok=True)\n'
         "            f.write_text(e['id'] + '\\n')\n"
         '        except OSError as ex:\n'
         "            print(f'could not add {f}: {ex}', file=sys.stderr)\n"),
        # Downloaded AppImages: extract-and-run when /dev/fuse is missing, not only when
        # the fusermount tools are (the Selkies image has the tools but no /dev/fuse).
        ("        'if ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; then\\n'\n",
         "        '# (containers often have the fusermount tools but no /dev/fuse)\\n'\n"
         "        'if [ ! -w /dev/fuse ] || { ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; }; then\\n'\n"),
    ],
}

for rel, patches in PATCHES.items():
    f = ROOT / rel
    src = f.read_text()
    for old, new in patches:
        if new in src:
            continue
        if src.count(old) != 1:
            sys.exit(f'{f}: patch text not found exactly once:\n{old}')
        src = src.replace(old, new)
    f.write_text(src)
    print(f'patched {f}')
