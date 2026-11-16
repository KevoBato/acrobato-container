#!/bin/sh
# usage: launch-test.sh <system>  -- launches first game, reports emulator state
API=http://127.0.0.1:1234
L=/config/.local/share/acrobato/system/logs
rom=$(curl -s "$API/systems/$1/games" | python3 -c 'import json,sys; g=json.load(sys.stdin); print(g[0]["path"])')
echo "ROM: $rom"
curl -s -X POST --data-binary "$rom" "$API/launch" >/dev/null
sleep 15
pgrep -a retroarch || echo "retroarch NOT running"
grep -hE "Running command|rror|xception" $L/batocera-launch.log | tail -8 | cut -c1-300
tail -5 $L/es_launch_stderr.log
