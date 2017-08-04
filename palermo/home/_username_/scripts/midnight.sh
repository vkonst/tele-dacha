#!/bin/bash
# midnight.sh: archive snapshots and movies for "motion"
# + (at midnight it moves files into dated directories)

# Folders with snapshot and movies to be archived
declare -a TARGET_DIRs
TARGET_DIRs[1]="/home/motion/cam1"
TARGET_DIRs[2]="/home/motion/cam2"
TARGET_DIRs[3]="/home/motion/cam3"
TARGET_DIRs[4]="/home/motion/cam4"

# Folders to archive into
declare -a COPY_DIRs[1]
COPY_DIRs[1]="/home/motion/archive/cam1"
COPY_DIRs[2]="/home/motion/archive/cam2"
COPY_DIRs[3]="/home/motion/archive/cam3"
COPY_DIRs[4]="/home/motion/archive/cam4"

# Symlinks to fresh archives (last dated directories)
declare -a LAST_LINKs[1]
FRESH_LINKs[1]="/var/www/webcams/cam1-lastarchive"
FRESH_LINKs[2]="/var/www/webcams/cam2-lastarchive"
FRESH_LINKs[3]="/var/www/webcams/cam3-lastarchive"
FRESH_LINKs[4]="/var/www/webcams/cam4-lastarchive"

# How long to keep archived files (in seconds)
declare -a KEEP_SECs
KEEP_SECs[1]="8640000"	# 100 days
KEEP_SECs[2]="8640000"  # 100 days
KEEP_SECs[3]="8640000"  # 100 days
KEEP_SECs[4]="8640000"  # 100 days

#LOGGER="cat"
#LOG_FILE=/var/log/webcams.log
#LOGGER="tee -a $LOG_FILE"
LOGGER="logger -t midnight.sh[$$]"

echo `date` midnight.sh started | $LOGGER

DATE=`date -d yesterday +%F`
SCOPE=`date -d yesterday +%Y%m%d`
#DATE=$1	#ex: 2014-12-09
#SCOPE=$2	#ex: 20141209
TODAY=`date +%s`

function move_files {
  local f
  #echo "move_files"

  if [ ! -x $COPY_DIR/$DATE ]; then 
    mkdir $COPY_DIR/$DATE | $LOGGER
    ln -s -T -f $COPY_DIR/$DATE $FRESH_LINK | $LOGGER
  fi
  cd $TARGET_DIR

  files=`ls -1 | grep $SCOPE`

  #echo SCOPE: $SCOPE FILES: $files

  for f in $files; do
   #echo FILE:$f
   mv -f -n $f $COPY_DIR/$DATE/$f | $LOGGER
  done

  rm  -f $COPY_DIR/$DATE/lastsnap.jpg | $LOGGER
}

function cleanup-dirs {
  local f
  #echo "cleanup-dirs"

  cd $COPY_DIR

  for d in *; do

    if [ -d $d ]; then

      FILETIME=`date +%s -r $d`

      if [ $? -eq 0 ]; then
        DIFF=`expr $TODAY - $FILETIME`
          if [ $DIFF -gt "$KEEP_SEC" ]; then 
            #echo "$d $DIFF more than $KEEP_SEC, say bye bye"
            cd $d
            # move files, then remove dir if it is empty
            for f in `ls -1`; do rm -f $f | $LOGGER; done
            cd ..
            rmdir $d | $LOGGER
          #else
            #echo $d $DIFF "OK"
          fi
      #else
        #echo $d "is not a dated directory"
      fi

    fi
  done
}

for i in `seq 1 ${#TARGET_DIRs[*]}`; do
  TARGET_DIR=${TARGET_DIRs[$i]}
  COPY_DIR=${COPY_DIRs[$i]}
  FRESH_LINK=${FRESH_LINKs[$i]}
  KEEP_SEC=${KEEP_SECs[$i]}
  #echo "i:$i; TARGET_DIR:$TARGET_DIR; COPY_DIR=$COPY_DIR; KEEP_SEC=$KEEP_SEC; TODAY=$TODAY"
  # move files in dated directory
  move_files
  # remove old directories and files
  cleanup-dirs
done
