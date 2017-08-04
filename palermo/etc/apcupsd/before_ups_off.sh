#!/bin/bash
#
# file:/etc/apcupsd/before_shutdown.sh

ssh root@toledo -i /home/_username_/.ssh/some_key_file "/sbin/poweroff" > /dev/null 2>&1 &
ssh root@1w-server -i /home/_username_/.ssh/some_key_file "/sbin/poweroff" > /dev/null 2>&1 &


