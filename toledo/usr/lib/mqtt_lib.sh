#!/bin/ash

### read config file
. /etc/mqtt/mqtt.conf

### declare global variables
msg_text=""          # message string (i.e. topic and payload: "vkhome-fi/sensors/temperature-outdoor 28.6 @1429627454")
msg_topic=""         # message topic (ex: "vkhome-fi/sensors/temperature-outdoor")
msg_payload=""       # message payload (i.e. value and timestamp: "28.6 @1429627454")
msg_value=""         # message value (ex.: "28.6")
msg_time=""          # message timestamp (ex.: "1429627454")

### mosquitto_pub and mosquitto_sub wrappers

mqtt_pub() {
# Publish a message from STDIN with the mqtt broker
# $1 - [mandatory] subtopic to publish the message on ("default" if unset)
# $2 - [optional] parameters for mosquitto_pub

[ -n "${debug}" ] && echo "*DEBUG* mqtt_pub $@" >&2
[ -z "$1" ] && local subtopic="default" || local subtopic="$1"; shift
[ -n "${debug}" ] && echo "*DEBUG* mqtt_pub subtopic=${subtopic}" >&2

mosquitto_pub -h "${MQTT_broker}" -p "${MQTT_port}" -u "${MQTT_user}" -P "${MQTT_passw}" \
-t "${MQTT_root_topic}/${subtopic}" -l $@
return $?
}

mqtt_sub() {
# Subscribe to a topic and print mqtt messages on STDOUT
# $1 - [mandatory] subtopic to subscribe ("#" if unset)
# $2 - [optional] parameters for mosquitto_pub

[ -n "${debug}" ] && echo "*DEBUG* mqtt_sub $@" >&2
[ -z "$1" ] && local subtopic="#" || { local subtopic="$1"; shift; }
[ -n "${debug}" ] && echo "*DEBUG* mqtt_sub subtopic=${subtopic}" >&2

if [ -n "${MQTT_clientID}" ]; then
 local param="-v -t ${MQTT_root_topic}/${subtopic} -t ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} $@ \
 -i ${MQTT_clientID} --will-topic ${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID} --will-payload 0 --will-retain"
else
 local param="-v -t ${MQTT_root_topic}/${subtopic} $@"
fi
[ -n "${debug}" ] && echo "*DEBUG* mqtt_sub param=${param}" >&2

mosquitto_sub -h "${MQTT_broker}" -p "${MQTT_port}" -u "${MQTT_user}" -P "${MQTT_passw}" ${param}
return $?
}

### Core functions

mqtt_parse_message () {
[ -n "${debug}" ] && echo "*DEBUG* mqtt_parse_message $@" >&2
msg_topic=''; msg_value=''; msg_time='' 
[ -n "$1" ] && msg_topic="$1" || return 1
[ -n "${debug}" ] && echo "*DEBUG* mqtt_parse_message msg_topic=${msg_topic}" >&2
[ -n "$2" ] && msg_value="$2" || return 2
[ -n "${debug}" ] && echo "*DEBUG* mqtt_parse_message msg_value=${msg_value}" >&2
[ -z "$3" ] && return 0            #timestamp is unset
[ "${3:0:1}" != '@' ] && return 3  #timestamp shell begin with '@'
if ! date -d "$3" >/dev/null 2>&1; then
 return 4                          #invalid timestamp (valid example: @1433238687) 
fi
msg_time="${3/@/}"
[ -n "${debug}" ] && echo "*DEBUG* mqtt_parse_message msg_time=${msg_time}" >&2
return 0
}

mqtt_read_messages () {
# Read mqtt messages on the subtopic and print every line to STDOUT
# $1 - [mandatory] subtopic to read the message (line) from
# $2 - [optional] parameters for mosquitto_sub
[ -n "${debug}" ] && echo "*DEBUG* mqtt_read_messages $@" >&2
mqtt_sub $@ |
while read -r msg_text ; do
 if mqtt_parse_message ${msg_text}; then
  if [ -n "{MQTT_clientID}" ] && [ "${msg_topic}" == "${MQTT_root_topic}/${MQTT_presence_topic}/${MQTT_clientID}" ]; then
    [ "${msg_value}" -eq "0" ] && echo "1" | mqtt_pub "${MQTT_presence_topic}/${MQTT_clientID}" -r
  else
    callback "${msg_text}"
  fi
 else
  on_error "mqtt_read_messages ERROR: $?"
 fi
done
}

mqtt_pub_stamped_plaintext() {
# Publish a time stamped message with the value word from STDIN
# the payload (message string) has two words: the value and the timestamp (ex.: 28.6 @1429627454)
# $1 - [mandatory] subtopic to publish the message on ("default" if unset)
# $2 - [optional] parameters for mosquitto_pub
# STDIN - value (one word) of the message to publish
local _msg="`cat` @`date +%s`"
echo "${_msg}" | mqtt_pub $@
return $?
}

### Callback functions

callback() { echo "${*}"; }
on_error() { echo "${*:-`cat`}" >&2 ; }
