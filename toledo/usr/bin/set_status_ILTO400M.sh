#!/bin/sh

# Set the desired state (on|off) for ILTO 400M.
# See usage bellow

STATUS_FILE="/tmp/ILTO400M.status"

if [ -f $STATUS_FILE ]; then
	mode=$(cat $STATUS_FILE | sed -n 's/.\?mode\ \?=\ \?\(manual\|auto\)/\1/p')
        state=$(cat $STATUS_FILE | sed -n 's/.\?state\ \?=\ \?\(on\|off\)/\1/p')
else
        echo "Error: can't read $STATUS_FILE. does it exist?" >&2
	echo "Creating empty $STATUS_FILE."
	touch $STATUS_FILE
        exit 1
fi

case "$1$2" in
	on|onauto|autoon)
	if ! [ "$mode" = "manual" ]; then
        	(echo `date`; echo "mode=auto"; echo state="on") > $STATUS_FILE
	fi
	;;

	off|offauto|autooff)
        if ! [ "$mode" = "manual" ]; then
                (echo `date`; echo "mode=auto"; echo state="off") > $STATUS_FILE
        fi
	;;

        onmanual|manualon)
		(echo `date`; echo "mode=manual"; echo state="on") > $STATUS_FILE
        ;;

        offmanual|manualoff)
        	(echo `date`; echo "mode=manual"; echo state="off") > $STATUS_FILE
        ;;

	onswitch|switchon|offswitch|switchoff|switch)
	        (echo `date`; echo "mode=auto"; echo "state=${state}") > $STATUS_FILE
        ;;

	*)
	(echo "Usage: set_status_ILT400M.sh on|off [auto|manual|switch]"
	 echo "\"manual\" has higher priority and it always overwrites the state."
	 echo "\"auto\" cann't reset the state if it was set in \"manual\" mode."
	 echo "\"switch\" does not reset the state. it sets the mode to \"auto\"."
	 echo "Use cron daemon or other scripts to call this scripts."
	 echo "GMT time is 2 hrs (7200s) behind the local time."
	) >&2
	result="1"
	;;

esac
exit $result
