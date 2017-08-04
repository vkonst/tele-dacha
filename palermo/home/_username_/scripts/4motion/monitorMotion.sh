#!/bin/bash
# Monitor if "motion" process is running and restart it, if not..

/usr/sbin/if_proc_run motion

case "$?" in

	0)
		# motion is running
		echo `date` NO ACTIONS
		;;
	113)
		# motion is NOT running

		echo `date` RESTARTING MOTION
		motion

		/usr/sbin/if_proc_run motion

		if [ "$?" -eq 0 ]; then
			RESULT=OK
		else
			RESULT=Failed 
		fi

		echo `date` motion restart $RESULT

		# send notification email
		/home/_username_/4motion/send_event_sms.sh  `date +%Y%m%d%H%M%S`-restart-$RESULT
		;;
	*)
		echo FAILED TO CHECK IF MOTION IS RUNNING
		exit 1
		;;
esac

