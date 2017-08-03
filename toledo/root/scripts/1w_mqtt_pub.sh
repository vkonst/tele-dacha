#!/usr/bin/env bash
#/bin/sh
# file /root/scripts/1w_mqtt_pub.sh
# on toledo
#

. /root/scripts/create_pid_or_exit_on_existing_pid.sh
. /etc/mqtt/mqtt.conf

MQTT_clientID="1w_sys-at-toldeo"
subtopic="sensors/all"

while true; do

  mosquitto_pub -h $MQTT_broker -p $MQTT_port -u $MQTT_user -P "${MQTT_passw}" \
     -i ${MQTT_clientID} --will-topic ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} --will-payload 0 --will-retain \
     -t ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} -m "@`date +%s`"

  if [ -f /tmp/1w_mqtt.log ]; then
   tail -f /tmp/1w_mqtt.log | \
   mosquitto_pub -h $MQTT_broker -p $MQTT_port -u $MQTT_user -P "${MQTT_passw}" \
     -i ${MQTT_clientID} --will-topic ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} --will-payload 0 --will-retain \
     -t "$MQTT_root_topic/$subtopic" -l
  fi

  echo waiting for log file
  sleep 5

done

