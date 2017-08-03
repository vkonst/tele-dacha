#!/bin/sh
# Switch on or off the power supply of the main USB hub

case $1 in

	on)
	/opt/usr/bin/owwrite  /uncached/3A.66XXXXXXXXXX/PIO.BYTE 0
	result="$?"
	echo "`date -Iseconds`;write;3A.66XXXXXXXXXX;PIO.BYTE;0;($result)"
	;;

	off)
        /opt/usr/bin/owwrite  /uncached/3A.66XXXXXXXXXX/PIO.BYTE 2
        result="$?"
        echo "`date -Iseconds`;write;3A.66XXXXXXXXXX;PIO.BYTE;2;($result)"
	;;

        toggle)
        /opt/usr/bin/owwrite  /uncached/3A.66XXXXXXXXXX/PIO.BYTE 2
        result="$?"
        echo "`date -Iseconds`;write;3A.66XXXXXXXXXX;PIO.BYTE;2;($result)"
	/usr/bin/usleep 0.3
        /opt/usr/bin/owwrite  /uncached/3A.66XXXXXXXXXX/PIO.BYTE 0
        result="$?"
        echo "`date -Iseconds`;write;3A.66XXXXXXXXXX;PIO.BYTE;0;($result)"
        ;;

        turn_of_for_300_secs)
        /opt/usr/bin/owwrite  /uncached/3A.66XXXXXXXXXX/PIO.BYTE 2
        result="$?"
        echo "`date -Iseconds`;write;3A.66XXXXXXXXXX;PIO.BYTE;2;($result)"
        echo "`date` switching off the main USB hub for 300 seconds"
        /bin/sh -c "\
          /bin/sleep 300; \
          /opt/usr/bin/owwrite /uncached/3A.66XXXXXXXXXX/PIO.BYTE 0; \
          echo \"\`date -Iseconds\`;write;3A.66XXXXXXXXXX;PIO.BYTE;0;($?)\";
          " > /dev/null 2>&1 &
        ;;

	*)
	echo "[$$]: Error: incorrect command (expected on|off|toggle|turn_of_for_300_secs)" >&2
	result="1"
	;;
esac
exit $result
