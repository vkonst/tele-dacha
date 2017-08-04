#!/bin/bash
# file: scripts/mqtt.d/entrance_door.sh
# host: palermo (vkhome-fi)

. ~/scripts/create_pid_or_exit_on_existing_pid.sh
. /usr/local/lib/mqtt_lib.sh

# by default:
# _payload_parser='_parse_as_stamped_plaintext'
# the payload contains two words: the value and the timestamp (ex.: 28.6 @1429627454)
# MQTT_root_topic='vkhome-fi'
# topics begin from vkhome-fi (ex.: vkhome-fi/sensors/count-entrance_doors)

# ENTRANCE DOORS - if doors opened
while true; do
  mqtt_monitor_topic 'sensors/count-entrance_doors' \
  'opened(%s)' '' '' '' 'mqtt_pub_stamped_plaintext security/doors -r'
  sleep 60
done

