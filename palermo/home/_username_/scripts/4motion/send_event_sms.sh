#!/bin/bash

#on_event action for /usr/bin/motion
#sends email to email@sms gate
#usage in motion.conf:
#on_event_start /home/_username_/4motion/send_event_sms.sh %C
#where %C - event text ID

LOGFILE=/home/_username_/4motion/monitorMotion.log
TEMPFILE=email.msg

# Email settings
RECEPIENT=username@gmail.com
FROM=username@gmail.com
SUBJECT="MOTION EVENT "$1
BODY="motion process on vkhome.fi detected an event "$1

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
rm -f $TEMPFILE
