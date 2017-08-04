#!/bin/bash

# Temporary script to query and Motion detection status and send it with SMS

LOGFILE=/home/_username_/4motion/monitorMotion.log
TEMPDIR=/tmp/motion_check.$$
TEMPFILE=$TEMPDIR/email.msg

mkdir -v $TEMPDIR
cd $TEMPDIR

# Get status info
CONNECTION=`w3m -dump  http://localhost:8080/0/detection/connection | grep -c "Connection OK"`
DETECTION=`w3m -dump  http://localhost:8080/0/detection/status | grep -c "Detection status ACTIVE"`
MOVIES=`find /tmp/motion -mtime -1 -name *.avi | grep -c .avi`
FOTOS=`find /tmp/motion -mtime -1 -name *.jpg | grep -v -c snap`
SNAPS=`find /tmp/motion -mtime -1 -name *snap*.jpg | grep -v -c lastsnap`

# Email settings
RECEPIENT=_username_@gmail.com
FROM=username@gmail.com
SUBJECT="MOTION Status report"
BODY="Motion= Connected:$CONNECTION. Detecting:$DETECTION. Last 24h: $MOVIES movies, $FOTOS event fotos, $SNAPS snapshots"

#preparing email
rm -f $TEMPFILE
echo To: $RECEPIENT > $TEMPFILE
echo From: $FROM >> $TEMPFILE
echo Subject: $SUBJECT >> $TEMPFILE
echo User-Agent: The command line MSMTP >> $TEMPFILE
echo >> $TEMPFILE
echo $BODY >> $TEMPFILE

# sending email

echo `date` event email sending >> $LOGFILE
echo $BODY >> $LOGFILE

msmtp $RECEPIENT < $TEMPFILE
if [ "$?" -ne "1" ]; then
    RESULT=Success
else
    RESULT=Failed
fi

echo sending $RESULT >> $LOGFILE

#cleaning tempfiles
rm -f -v $TEMPFILE
rmdir -v $TEMPDIR
