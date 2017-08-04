#!/bin/sh
#
# Script: /usr/sbin/delayed_reboot.sh
# The script reboots the system
# + if "theFILE" has not been updated
# + within "thePERIOD" or not found.
# Script /usr/bin/delay_reboot.sh
# + is supposed to updates "theFILE"

# The file that prevents rebooting
theFILE="/tmp/do_not_restart"
# The file shall be updated within past 12h (defined in s)
thePERIOD=43200

stamp=`echo "\`date\` $0"`

if [ -f $theFILE ]; then

 NOW=`date +%s`
 updateTIME=`date +%s -r $theFILE`
 DIFF=`expr $NOW  - $updateTIME`

 if [ $DIFF -le $thePERIOD ]; then
   logger -s "$stamp found \"fresh\" $theFILE. System reboot postponed."
   exit 0
 fi

fi

logger -s "$stamp has not found \"fresh\" $theFILE. System reboot called."
/sbin/shutdown -r now

