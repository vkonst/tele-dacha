#/bin/sh
# file: scripts/mqtt.d/vkhome-fi_mqtt-pub.sh
# host: palermo (vkhome-fi)
# Publish messages from local MQTT sever on the cloud MQTT server

. ~/scripts/create_pid_or_exit_on_existing_pid.sh

. /etc/mqtt/mqtt.conf

sudo /etc/init.d/mosquitto status; RES="$?"
[ "$RES" -eq "0"  ] || sudo /etc/init.d/mosquitto start


MQTT_clientID="publisher-at-vkhome-fi"

while true; do
  mosquitto_sub -h ${MQTT_broker} -p ${MQTT_port} \
                -u ${MQTT_user}   -P "${MQTT_passw}" \
                -t "${MQTT_root_topic}/#" \
                -T "${MQTT_root_topic}/sensors/all" \
                -v | \

  mosquitto_pub -h ${MQTT_cloud_broker} -p ${MQTT_cloud_ssl_port} --capath ${MQTT_cloud_capath} \
                --keepalive 15 \
                -u ${MQTT_cloud_user}   -P "${MQTT_cloud_passw}" \
                -i ${MQTT_clientID} --will-topic ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} --will-payload 0 --will-retain \
                -t "${MQTT_cloud_root_topic}/all" -l
  sleep 5
done
