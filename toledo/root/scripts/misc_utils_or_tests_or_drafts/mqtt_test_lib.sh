#!/usr/bin/env bash
#/bin/ash

while true; do
  if [ -f /tmp/1w_mqtt.log ]; then
   tail -f /tmp/1w_mqtt.log | \
   while read -r topic message; do
    /opt/usr/bin/mosquitto_pub -h 192.168.XXX.XX7 -p 1883 -u username -P "password" -t "vkhome-fi/sensors/$topic" -m "$message"
   done
  fi
  sleep 5
done

