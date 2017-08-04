#!/bin/bash
# file: scripts/mqtt.d/watermeter_datastream.sh
# host: palermo (vkhome-fi)
# hack to stream mqtt data to watermeter web page

. ~/scripts/create_pid_or_exit_on_existing_pid.sh
. /etc/mqtt/mqtt.conf

local chip="count-water_meter";
local value timestamp rest;

while true; do
	mosquitto_sub -h $MQTT_broker -u $MQTT_user -P $MQTT_passw -t "${MQTT_root_topic}/sensors/${chip}" | \
        
	while read -r value timestamp rest; do
		echo "{ \"chip\": \"$chip\", \"time\":${timestamp/@/}, \"value\":$value }" > /var/www/water/getReading.json
	done
	sleep 60
done 2>&1
