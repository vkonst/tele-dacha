#!/bin/sh

# Switch ILTO 400M on or off as defined in $STATUS_FILE
# $STATUS_FILE shall have a line with "state=on" or "state=off"
# Use cron daemon or other scripts to update $STATUS_FILE
# NB: GMT time is 2 hrs (7200s) behind the local time

STATUS_FILE="/tmp/ILTO400M.status"
# CMD_SWITCH_ON=""
# CMD_SWITCH_OFF=""

if [ -f $STATUS_FILE ]; then
	status=$(cat $STATUS_FILE | sed -n 's/.\?state\ \?=\ \?\(on\|off\)/\1/p')
else
        echo "Error: can't read $STATUS_FILE. does it exist?" >&2
        exit 1
fi

case $status in
	on)
	# $CMD_SWITCH_ON
	/opt/usr/bin/owwrite /05.2EXXXXXXXXXX/PIO 1
	result="$?"
	echo "`date -Iseconds`;write;05.2EXXXXXXXXXX;PIO;1;($result)"
	;;

	off)
	# $CMD_SWITCH_OFF
        /opt/usr/bin/owwrite /05.2EXXXXXXXXXX/PIO 0
        result="$?"
        echo "`date -Iseconds`;write;05.2EXXXXXXXXXX;PIO;0;($result)"
	;;

	*)
	echo "Error: desired status incorrectly defined in $STATUS_FILE" >&2
	result="1"
	;;
esac
exit $result
