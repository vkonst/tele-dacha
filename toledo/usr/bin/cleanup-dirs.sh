#! /bin/sh

LOGGER="/usr/bin/logger -t cleanup-dirs.sh[$$]"

cd /home/webcam/archive

for i in *
do

if [ -d $i ]
then
TODAY=`date +%s`
FILETIME=`date +%s -r $i`

if [ $? -eq 0 ]
then
DIFF=`expr $TODAY - $FILETIME`

if [ $DIFF -gt 1209600 ]
then
echo "$i is more than 14 days old.. deleting.." | $LOGGER
cd $i
# remove a lot of files, then remove dir
for f in `ls -1`; do
 rm  -f $f
done
cd ..
rmdir $i
else
echo $i $DIFF "OK"
fi

else
echo $i "is not a dated directory"
fi

fi
done

