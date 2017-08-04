#! /bin/sh

cd /home/_username_/motion_copy

for i in *
do

if [ -d $i ]
then
TODAY=`date +%s`
FILETIME=`date +%s -d $i`

if [ $? -eq 0 ]
then
DIFF=`expr $TODAY - $FILETIME`

if [ $DIFF -gt 7776000 ]
then
echo $i $DIFF "more than 90 days, say bye bye"
cd $i
# remove a lot of files, then remove dir
ls -1 | xargs -n 10 -i rm -f {}
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
