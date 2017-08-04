#!/bin/bash
# draft yet ...

_listen()
{

  if [ -n "$2" ]; then 
    _Seconds=`echo "$2" | grep -E "[09]+"`;
  else
    _Seconds="30"
  fi
  
  case $1 in
    lake|"")
      arecord -D default:CARD=U0x46d0x8b5 -d ${_Seconds} -f cd -t raw | oggenc - -r
      ;;
    hpump)
      arecord -D default:CARD=C920 -d ${_Seconds} -f cd -t raw | oggenc - -r
      ;;
    road)
      ssh 1w-server 'arecord -d ${_Seconds} -f cd -t raw' | oggenc - -r
      ;;
    *)
      echo "usage: _listen [lake|hpump|road] [time_in_seconds_to_listen"]
      ;;
  esac
}

for i in `seq 1 3`; do 
  echo "=== start $i `date`"
  _listen road 10  > vkhome-fi_road_mic_sound_`date +%s`
  echo "=== done $i `date`"
  sleep 1740
done
