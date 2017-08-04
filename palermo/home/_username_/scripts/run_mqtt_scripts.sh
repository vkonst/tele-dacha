#!/bin/bash
# host: vjhome-fi
# file: scripts/run_mqtt_monitors.sh

# run matched scripts in background
for file in ~/scripts/mqtt.d/*.sh; do
    [ -f "$file" ] && [ -x "$file" ] && "$file" &
done
