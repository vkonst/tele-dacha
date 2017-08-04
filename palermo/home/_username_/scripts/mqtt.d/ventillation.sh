#!/bin/bash
# file: scripts/mqtt.d/ventillation.sh
# host: palermo (vkhome-fi)

. ~/scripts/create_pid_or_exit_on_existing_pid.sh
. /usr/local/lib/mqtt_lib.sh

# VENTILLATION SYSTEM - pub message if switched on/off
while true; do
 mqtt_monitor_topic 'sensors/digt_in-ventillation_switch' \
 '%s' '' '' 'on_or_off' 'mqtt_pub_stamped_plaintext ventillation/central_unit -r'
 sleep 60
done
