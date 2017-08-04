#!/bin/bash
# CGI interface for switching on/off the usb-hub@vkhome-fi.debian (via 1w_sys@toledo)
# DO NOT RUN IT UNLESS YOU CLEAR UNDERSTAND THE OUTCOMES

usage() {
 echo "usage: $0 [[[-q QUERY_STRING] [--no_header]] | [-h]]"
 echo "switching on/off the usb-hub@vkhome-fi.debian (via 1w_sys@toledo)"
 echo "*** DO NOT RUN IT UNLESS YOU CLEAR UNDERSTAND THE OUTCOMES"
 echo
 echo "Optional arguments:"
 echo "-q, --query	- url query string"
 echo "--no_header	- do not print html header (default: print html header)"
 echo "-h, --help	- display this help and exit"
 echo
 echo -n "Query string. "
 query_usage
}

query_usage() {
 echo "cmd=on|off|toggle|turn_of_for_300_secs"
 echo "header=no"
}

silent() {
  if [ "$debug" == "yes" ]; then
   "$@" 2>&1
  else
   "$@" > /dev/null 2>&1
  fi
}

parse_query_string() {
local name=''; local value=''; local param=''
for param in $(tr "&" "\n" <<<"$@"); do
  name=$(cut -f 1 -d "=" <<<"$param")
  value=$(cut -f 2 -d "=" <<< "$param")
  case ${name} in
    cmd)     CMD="${value}";;
    header) header="no";;
    *) : # usage
    ;;
  esac
done 
}

run_cmd() {
case ${CMD} in
  on|off|toggle|turn_of_for_300_secs)
    if pub_mqtt_cmd; then echo "${CMD} Ok"; else echo "${CMD} Failure"; fi ;;
  *)
    echo "date: `date -Is`</br>"
    echo "URL: ${QUERY_STRING}</br>"
    ;;
esac
}

pub_mqtt_cmd() {
. /etc/mqtt/mqtt.conf
subtopic="servers/control/usbhub"
mosquitto_pub -h $MQTT_broker -p $MQTT_port -u $MQTT_user -P "${MQTT_passw}" \
  -t "$MQTT_root_topic/$subtopic" -m "${CMD}  @`date +%s`"
}

# "Global" variables:
CMD=''

while [ "$1" != "" ]; do
 case $1 in
   -q | --query)   shift
                   QUERY_STRING="$1"
                   ;;
   --no_header )   header="no"
                   ;;
   -h | --help )   usage
                   exit
                   ;;
    * )            : # usage
                   # exit 1
    esac
    shift
done

parse_query_string ${QUERY_STRING}

if [ "$header" != "no" ]; then
 echo "Content-type: text/html"
 echo
 echo  "<html>"
 echo  "<head>"
 echo  "<title>Ventillation control API</title>"
 echo  "</head>"
 echo  "<body>"
fi

run_cmd

if [ "$header" != "no" ]; then
  echo  "</body>"
  echo  "</html>"
fi
