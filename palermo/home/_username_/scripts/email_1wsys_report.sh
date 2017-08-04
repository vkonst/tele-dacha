#!/bin/sh

ADMIN=root,_username_@gmail.com
MAIL="mail"
HOSTNAME=`hostname`
MSG="$HOSTNAME 1w_sys report"
#
(
   echo "Subject: $MSG"
   echo " "
   echo "$MSG"
   echo " "
   echo "*** LOG UPDATES:"
   ssh toledo "ls /home/1w/*.log -ls" | awk '{print $7,$8,$9, $10}'

   echo "*** SENSORS:"
   export QUERY_STRING="format=text"
   /home/_username_/scripts/re3m_get-updates-for-last-two-minutes.cgi

   # echo "*** TEMPERATURES:"
   # ssh toledo "tail -n 23 /home/1w/1w_collectd.log | sed -e 's/interval=[0-9\ ]*//' | sed -e 's/1w_sys\/temperature-//'"
   # echo "*** COUNTERS"
   # ssh toledo "grep -E '1D\..*count' /home/1w/sensor_readings.log | head -n 2; grep -E '1D\..*count' /home/1w/sensor_readings.log | tail -n 2 "

   echo "*** ROADCAM MOTION MOVIES:"
   /bin/ls /home/motion/cam3/*.swf -lsh | awk '{print $6,$9}'
   echo "*** SYSTEM HELTH:"
   /sbin/apcaccess status | grep -E "BCHARGE|LOAD|BATTV"
   df -h | grep -E "rootfs|sda2" | awk '{print $4,$5,$6}'
   sensors | grep -E "temp1|Core"
) | $MAIL -s "$MSG" $ADMIN
exit 0

