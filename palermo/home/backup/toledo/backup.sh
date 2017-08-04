#!/bin/sh
RSYNC="/usr/bin/rsync -avL -e ssh"
TRGDIR=/home/backup/toledo
$RSYNC root@toledo:/etc/ $TRGDIR/etc/
$RSYNC root@toledo:/root/ $TRGDIR/root/

