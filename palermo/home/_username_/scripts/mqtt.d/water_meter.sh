#!/bin/bash
# file: scripts/mqtt.d/water_meter.sh
# host: palermo (vkhome-fi)

. ~/scripts/create_pid_or_exit_on_existing_pid.sh
. /usr/local/lib/mqtt_lib.sh

# ENTRANCE DOORS - if doors opened
while true; do
  mqtt_monitor_topic 'sensors/count-water_meter' \
  'flow_detected(%s)' '' 100 '' 'mqtt_pub_stamped_plaintext security/water_meter -r'
  sleep 60
done

