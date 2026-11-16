#!/bin/bash
# Waits (up to $1 s) for EmulationStation's pid to change, then prints the process
# snapshots taken just before and after, to see who stopped it.
end=$((SECONDS + ${1:-280}))
es=$(pgrep -x emulationstatio)
prev2=""; prev1=""
while [ $SECONDS -lt $end ]; do
  snap="$(date +%T.%N | cut -c1-12)
$(ps -eo pid,ppid,stat,etime,args --sort=pid | grep -vE ' (ps|grep|sort|sleep|eswatch)' | cut -c1-170)"
  now=$(pgrep -x emulationstatio)
  if [ "$now" != "$es" ]; then
    echo "ES pid $es -> ${now:-none}"; echo "== before"; echo "$prev2"; echo "== before"; echo "$prev1"; echo "== now"; echo "$snap"
    exit 0
  fi
  prev2="$prev1"; prev1="$snap"
  sleep 0.2
done
echo "no ES restart within the time limit"
