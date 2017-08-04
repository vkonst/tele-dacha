#!/bin/sh
#
# Script: /usr/bin/delay_reboot.sh
# The script updates "theFILE"
# + for a process /usr/sbin/delayed_reboot.sh
# + that reboots the host if the file
# + was not updated for a certain time

theFILE="/tmp/do_not_restart"

stamp=`echo "\`date\` $0"`


echo "$stamp" > $theFILE

if [ $? -eq 0 ]; then
 result="0"
else
 result="1"
fi

logger -s "$stamp updated $theFILE ($result)"


