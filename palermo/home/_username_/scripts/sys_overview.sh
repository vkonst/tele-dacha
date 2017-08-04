#!/bin/sh

echo "*** 1W_SYS LOG UPDATES:"
/usr/bin/ssh toledo "ls /home/1w/*.log -ls" | awk '{print $7,$8,$9, $10}'
echo "*** TEMPERATURES:" 
/usr/bin/ssh toledo "tail -n 23 /home/1w/1w_collectd.log | sed -e 's/interval=[0-9\ ]*//' | sed -e 's/1w_sys\/temperature-//'" |\
grep -Ev "heat|hpump"
echo "*** COUNTERS"
/usr/bin/ssh toledo "grep -E '1D\..*count' /home/1w/sensor_readings.log | head -n 2; grep -E '1D\..*count' /home/1w/sensor_readings.log | tail -n 2 "
echo "*** ROADCAM MOTION MOVIES:"
/bin/ls /home/motion/cam3/*.swf -lsh | awk '{print $6,$9}'
echo "*** SYSTEM HELTH:"
/sbin/apcaccess status | grep -E "BCHARGE|LOAD|BATTV"
/bin/df -h | grep -E "rootfs|sda2" | awk '{print $4,$5,$6}'
/usr/bin/sensors | grep -E "temp1|Core"

exit 0

