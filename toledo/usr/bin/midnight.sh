#!/bin/sh

# at midnight we move everything into it's own dated directory

LOGGER="/usr/bin/logger -t midnight.sh[$$]"

TEMP=`date +%F`
SCOPE=`date +%Y%m%d`

TARGET_DIR=/home/webcam
COPY_DIR=/home/webcam/archive
LOG_FILE=/home/log/webcam.log

echo started | $LOGGER
mkdir $COPY_DIR/$TEMP | $LOGGER 
cd $TARGET_DIR

files=`ls -1 | grep $SCOPE`

# echo SCOPE: $SCOPE FILES: $files

for f in $files; do
 # echo FILE:$f
 mv -f -n $f $COPY_DIR/$TEMP/$f | $LOGGER 
done

rm  -f $COPY_DIR/$TEMP/lastsnap.jpg

# now remove old directories and files
/usr/bin/cleanup-dirs.sh
