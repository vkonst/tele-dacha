#!/bin/ash
# file: scripts/run_mqtt_monitors.sh

. /usr/lib/mqtt_lib.sh

MQTT_clientID='monitors-at-toledo'
listen_topic='+/control/+'

control_hpump() {
[ -n "${debug}" ] && echo "*DEBUG* control_hpump ${@}"
case "${msg_value}" in
  up|down|left|right|longleft)
    ../../usr/bin/keyboard_HeatPump.sh ${msg_value} 2>&1 ;;
  *) return 1 ;;
esac
}

control_vent() {
[ -n "${debug}" ] && echo "*DEBUG* control_vent ${@}"
case "${msg_value}" in
  on)   /usr/bin/set_status_ILTO400M.sh on  manual 2>&1 ;;
  off)  /usr/bin/set_status_ILTO400M.sh off manual 2>&1 ;;
  auto) /usr/bin/set_status_ILTO400M.sh switch 2>&1 ;;
  *) return 1 ;;
esac
}

control_main_usb_hub() {
[ -n "${debug}" ] && echo "*DEBUG* control_main_usb_hub ${@}"
case "${msg_value}" in
  on|off|toggle)
    /usr/bin/control_main_USB_hub.sh ${msg_value} 2>&1 ;;
  *) return 1 ;;
esac
}


callback() {
[ -n "${debug}" ] && echo "*DEBUG* callback ${@}"
case "${msg_topic}" in
  *heat_pump/control/keyboard)
    control_hpump ;;
  *ventillation/control/switch)
    control_vent ;;
  *servers/control/usbhub)
    control_main_usb_hub ;;
  *) return 2 ;;
esac
}

while true; do
  mqtt_read_messages "${listen_topic}"
  sleep 60
done

#for par in "$@"; do
#case "${par}" in
# --debug) debug="yes" ;;
# *) : ;;
#esac
#shift
#done
