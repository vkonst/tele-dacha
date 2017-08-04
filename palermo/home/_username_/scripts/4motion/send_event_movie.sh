#!/bin/bash

#on_movie_end action for /usr/bin/motion
#sends email with attached movie file to specified bellow recepients
#usage in motion.conf:
#on_movie_end /home/_username_/4motion/send_event_movie.sh %C %f
#where %C - event text, %f - movie file name with full path

LOGFILE=/home/_username_/4motion/monitorMotion.log

# Email settings
RECEPIENT=_username_@gmail.com
SUBJECT="MOTION MOVIE SHOT $1"
BODY="`date`: motion process on vkhome.fi detected an event $1 and shot event movie (attahced)."
ATTACHMENT=$2

# sending email and logging
echo `date` event movie sending: event=$1 file=$2 to $RECEPIENT >> $LOGFILE
echo $BODY | mutt -s "$SUBJECT" -a $ATTACHMENT $RECEPIENT -x >> $LOGFILE

if [ "$?" -ne "1" ]; then
	RESULT=Ok
else
	RESULT=Failed
fi

echo Result=$RESULT >> $LOGFILE

