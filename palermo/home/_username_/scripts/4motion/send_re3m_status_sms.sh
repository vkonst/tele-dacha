#!/bin/bash

# Temporary script to query re3m status and send it with SMS

LOGFILE=/home/_username_/4motion/monitorMotion.log
TEMPDIR=/tmp/motion_check.$$
TEMPFILE=$TEMPDIR/email.msg

mkdir -v $TEMPDIR
cd $TEMPDIR

# Email settings
RECEPIENT=username@gmail.com
FROM=username@gmail.com
SUBJECT="Re3m status"

#preparing email
rm -f $TEMPFILE
echo To: $RECEPIENT > $TEMPFILE
echo From: $FROM >> $TEMPFILE
echo Subject: $SUBJECT >> $TEMPFILE
echo User-Agent: The command line MSMTP >> $TEMPFILE
echo >> $TEMPFILE
w3m -dump -pauth username:password -T text/html http://192.168.XXX.XX3/Unslung/temploggerd/cgi-bin/status.cgi >> $TEMPFILE

# sending email

echo `date` event email sending >> $LOGFILE
cat $TEMPFILE >> $LOGFILE

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
