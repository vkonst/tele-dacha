#!/bin/bash
#
# Delay reboot of the host "toledo" with a help of ssh command.
# Supposed to be run every few hours
# If ssh connection works then the remote host shall not be rebooted.

REMOTE_HOST="root@192.168.XXX.XX2"
REMOTE_PORT="22"
ID="/home/_username_/.ssh/some_key_file"
REMOTE_CMD="/usr/bin/delay_reboot.sh"

echo "`/bin/date` $0"
ssh $REMOTE_HOST -p $REMOTE_PORT -i $ID "$REMOTE_CMD"

