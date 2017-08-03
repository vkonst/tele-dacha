#/bin/ash
# example print_1w_counter_change entrance_door

[ -z $2 ] && LOG="/home/1w/1w_collectd.log" || LOG="$2"
[ -z $1 ] && PATTERN="water_meter" || PATTERN="$1"

grep $PATTERN $LOG | tr -s ":" " "| cut -d " " -f 3,4 | \
while read -r stamp value; do
  [ -z "$ovalue" ] && ovalue="$value"
  if [ ! "$value" = "$ovalue" ]; then
    echo "`date -d@$stamp +%H:%M:%S` `expr $value - $ovalue`"; ovalue="$value"
  fi
done
