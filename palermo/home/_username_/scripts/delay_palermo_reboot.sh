#!/bin/bash
#
# Delay reboot of the local host ("palermo") with a help of ssh command.
# Co-operates with teh script "/usr/sbin/delayed_reboot.sh".
# Supposed to be run every few hours.
# The local host shall always keep a reverse ssh connection opened on the 'REMOTE_HOST'.
# If the reverse ssh connection opened then the local host shall not be rebooted.

LOGGER="/usr/bin/logger -t delay_palermo_reboot[$$]"

REMOTE_HOST="_username_@XXX.XXX.XXX.XXX"
REMOTE_PORT=remote_port
ID="/home/_username_/.ssh/some_key_file"

DELAY_REBOOT="/usr/bin/delay_reboot.sh"

if (ssh $REMOTE_HOST -p $REMOTE_PORT -i $ID \
  'netstat -ant |  grep -E "0\.0\.0.\0:remote_port.+LISTEN"') \
  > /dev/null 2>&1
then
  $LOGGER "reverse ssh connection detected"
  $DELAY_REBOOT
else
  $LOGGER "reverse ssh connection not found"
fi
