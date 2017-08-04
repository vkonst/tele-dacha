#!/bin/bash

# at midnight we move everything into it's own dated directory

TEMP=`date +%F`
SCOPE=`date +%Y%m%d`
MOTION_DIR=/tmp/motion
COPY_DIR=/home/_username_/motion_copy
LOG_FILE=/home/_username_/4motion/monitorMotion.log

echo `date` midnight.sh started >> $LOG_FILE
mkdir $COPY_DIR/$TEMP >> $LOG_FILE
cd $MOTION_DIR

ls -1 | grep $SCOPE | xargs -n 10 -i cp --preserve=timestamps {} $COPY_DIR/$TEMP/
rm -f $TEMP/lastsnap.jpg >> $LOG_FILE

# now remove old directories and files
/home/_username_/4motion/cleanup-dirs.sh >> $LOG_FILE

