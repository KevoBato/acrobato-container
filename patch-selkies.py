"""Patches Selkies' gamepad server (argv[1]: selkies/input_handler.py) so one program that
holds a virtual pad open without reading it can't freeze the pad for every program.

Upstream sends each event to every connected client in turn and awaits writer.drain().
When one client stops reading (for example a pad connection an emulator inherited and
never uses), its socket buffer fills, drain() waits forever, and no client gets input
again: in-game controls and hotkeys stop "out of nowhere". Here a client whose unsent
data passes 64 KiB is skipped (its events dropped) instead of waited on."""
import sys
from pathlib import Path

F = Path(sys.argv[1])
src = F.read_text()
LIMIT = '65536'
PATCHES = [
    ('                                writer.write(js_data)\n'
     '                                await writer.drain()\n',
     f'                                if writer.transport.get_write_buffer_size() < {LIMIT}:  # never wait on a client that stopped reading\n'
     '                                    writer.write(js_data)\n'),
    ('                                writer.write(evdev_data)\n'
     '                                await writer.drain()\n',
     f'                                if writer.transport.get_write_buffer_size() < {LIMIT}:  # never wait on a client that stopped reading\n'
     '                                    writer.write(evdev_data)\n'),
]
for old, new in PATCHES:
    if new in src:
        continue
    if src.count(old) != 1:
        sys.exit(f'{F}: patch text not found exactly once:\n{old}')
    src = src.replace(old, new)
F.write_text(src)
print(f'patched {F}')
