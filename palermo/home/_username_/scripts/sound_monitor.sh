#!/bin/bash 
# http://stackoverflow.com/questions/2613163/monitoring-an-audio-line
# Here's an even better one;
# sox -t alsa default ./recording.flac silence 1 0.1 5% 1 1.0 5%
# It produces an audio file, only when there is sound, and cuts out the silence. So no gaps and no long silences like the stuff above!

noise_threshold=3
storage_folder=~/recordings
raw_folder=~/recordings/tmp
split_folder=~/recordings/split
sox_raw_options="-t raw -r 48k -e signed -b 16"
split_size=1048576 # 1M

mkdir -p ${raw_folder} ${split_folder}

test -a ${raw_folder}/in.raw ||  mkfifo ${raw_folder}/in.raw

# start recording and spliting in background
rec ${sox_raw_options} - >${raw_folder}/in.raw 2>/dev/null &
split -b ${split_size} - <${raw_folder}/in.raw ${split_folder}/piece &

while true; do
    # check each finished raw file
    for raw in $(find ${split_folder} -size ${split_size}c);do
      max_level="$(sox $sox_raw_options  ${raw} -n stats -s 16 2>&1|awk '/^Max\ level/ {print int($3)}')"
      if [ $max_level -gt $noise_threshold ];then
        sox ${sox_raw_options} ${raw} ${storage_folder}/recording-$(date +%FT%T).wav;
      fi
      rm ${raw}
    done
    sleep 1
done
