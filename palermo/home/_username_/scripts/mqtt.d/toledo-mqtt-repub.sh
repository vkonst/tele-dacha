#/bin/sh
# file: scripts/mqtt.d/toledo-mqtt-repub.sh
# host: palermo (vkhome-fi)

. ~/scripts/create_pid_or_exit_on_existing_pid.sh
. /usr/local/lib/mqtt_lib.sh

sudo /etc/init.d/mosquitto status; RES="$?"
[ "$RES" -eq "0"  ] || sudo /etc/init.d/mosquitto start


MQTT_clientID="republisher-at-vkhome-fi"

while read -r topic message; do

  mqtt_pub "sensors/${topic}" <<< "${message}";

done < <(mqtt_sub 'sensors/all' --doNotDumpTopic)
