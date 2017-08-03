#!/bin/sh

# Switch on or off the "timer" mode of "Thermia Diplomat"
# as defined by $STATUS_FILE
# The $STATUS_FILE shall have one line with one word only:
# "on" or "off"
# Use cron daemon or other scripts to update $STATUS_FILE
# NB: cron job scheduled in GMT (2hrs behind local time)

STATUS_FILE="/tmp/heat_pump_timer_mode.status"
# CMD_SWITCH_ON=""
# CMD_SWITCH_OFF=""

if [ -f $STATUS_FILE ]; then
	status=`cat $STATUS_FILE`
else
        echo "control_HeatPump[$$]: Error: can't read $STATUS_FILE. does it exist?" >&2
        exit 1
fi

case $status in

	on)
	# $CMD_SWITCH_ON
	/opt/usr/bin/owwrite  /uncached/3A.66DEXXXXXXXX/PIO.BYTE 1
	result="$?"
	echo "`date -Iseconds`;write;3A.66DEXXXXXXXX;PIO.BYTE;1;($result)"
	;;

	off)
	# $CMD_SWITCH_OFF
        /opt/usr/bin/owwrite  /uncached/3A.66DEXXXXXXXX/PIO.BYTE 0
        result="$?"
        echo "`date -Iseconds`;write;3A.66DEXXXXXXXX;PIO.BYTE;0;($result)"
	;;

	*)
	echo "control_HeatPump[$$]: Error: desired status incorrectly defined in $STATUS_FILE" >&2
	result="1"
	;;
esac
exit $result
