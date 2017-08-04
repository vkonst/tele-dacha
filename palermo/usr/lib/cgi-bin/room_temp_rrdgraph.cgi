#!/bin/bash
# Create 1w_sys@toledo charts and html page

dbdir="/var/lib/collectd/rrd/toledo/1w_sys"
grdir="/var/www/include"
grpath="/include"

RRDTOOL="/usr/bin/rrdtool"
LSMODTIME="/bin/date -r"

usage() {
 echo "usage: room_temp_rrdgraph.cgi [[[-q QUERY_STRING] [-d folder] [--no_header]] | [-h]]"
 echo "Create 1w_sys@toledo charts and html page."
 echo
 echo "Optional arguments:"
 echo "-q, --query	- url query string"
 echo "-d, --dir	- folder to create charts in (default: $grdir)"
 echo "--no_header	- do not print html header (default: print html header)"
 echo "-h, --help	- display this help and exit"
 echo
 echo "Query string (all parameters are optional):"
 echo "timespan=TIMESPAN&start=START&debug=yes|no"
 echo "	(example: timespan=4hours&start=now-300m)"
 echo "TIMESPAN	- time period for charts in format of rrdgraph (default:hour)"
 echo "or predefined word: hour|4hours|day|36hours|week|2weeks|month|91days|year"
 echo "START	- time to start charts in format of rrdgraph (defults: now-timespan)"
 echo "	(examples: now,now-10800s,now-10h,now-2d,15:35,20150131)"
 echo "debug - print debug info in html code (default: no)"
}

silent() {
  if [ "$debug" == "yes" ]; then
   "$@" 2>&1
  else
   "$@" > /dev/null 2>&1
  fi
}

while [ "$1" != "" ]; do
 case $1 in
   -q | --query)   shift
                   QUERY_STRING="$1"
                   ;;
   -d | --dir )    shift
                   grdir="$1"
                   ;;
   --no_header )   header="no"
                   ;;
   -h | --help )   usage
                   exit
                   ;;
    * )            : # usage
                   # exit 1
    esac
    shift
done

if [ "$header" != "no" ]; then
echo "Content-type: text/html"
echo
echo  "<html>"
echo  "<head>"
echo  "<title>vkhome-fi room temperatures</title>"
echo  "</head>"
echo  "<body>"
fi

Start=`grep -oE "start=[a-zA-Z0-9+:\-]+"  <<< "$QUERY_STRING" | sed "s/start=//"`
Timespan=`grep -oE "timespan=[a-zA-Z0-9]+"  <<< "$QUERY_STRING" | sed "s/timespan=//"`
debug=`grep -oE "debug=[a-z]+"  <<< "$QUERY_STRING" | sed "s/debug=//"`

silent echo "Start=$Start; Timespan=$Timespan</br>"

case ${Timespan} in
 hour)
  Seconds="3600"; Period="60 minutes"
  ;;
 4hours)
  Seconds="14400"; Period="4 hours"
  ;;
 day)
  Seconds="86400"; Period="day"
  ;;
 36hours)
  Seconds="129600"; Period="36 hours"
  ;;
 3days)
  Seconds="259200"; Period="3 days"
  ;;
 week)
  Seconds="604800"; Period="week"
  ;;
 2weeks)
  Seconds="1209600"; Period="2 weeks"
  ;;
 month)
  Seconds="2678400"; Period="month"
  ;;
 91days)
  Seconds="7862400"; Period="3 monthes"
  ;;
 year)
  Seconds="31622400"; Period="year"
  ;;
 "")
  Seconds="3600"; Period="60 minutes"
  ;;
 *)
  Seconds=""; Period="$Timespan"
  ;;
esac

if [ -z "$Seconds" ]; then
  Seconds="$Timespan"
else
  Seconds="${Seconds}s"
fi

silent  echo "Seconds=$Seconds</br>"

if [ -z "$Start" ]; then
  End="now"
  Start="end-${Seconds}"
else
  End="start+${Seconds}"
  Period="$Period after $Start"
fi

silent echo "Start=$Start; End=$End</br>"

silent $RRDTOOL graph $grdir/counters.png -a PNG --width 800 \
--title="Detected human presence for past $Period" \
--vertical-label "Sensors" \
--end $End --start $Start \
"DEF:ir=$dbdir/count-indoor_ir_sensor.rrd:rate:AVERAGE" \
"DEF:doors=$dbdir/count-entrance_doors.rrd:rate:AVERAGE" \
"DEF:water=$dbdir/count-water_meter.rrd:rate:AVERAGE" \
"CDEF:door_sensors=doors,UN,UNKN,doors,0,GT,1,0.03,IF,2,+,IF" \
"CDEF:no_door=doors,0,GT,0,1,IF,2,+" \
"CDEF:water_meter=water,UN,UNKN,water,0,GT,1,0.03,IF,1,+,IF" \
"CDEF:no_water=water,0,GT,0,1,IF,1,+" \
"CDEF:ir_sensor=ir,UN,UNKN,ir,0,GT,1,0.03,IF,IF" \
"CDEF:no_ir=ir,0,GT,0,1,IF" \
"AREA:no_door#eaeaea" \
"AREA:door_sensors#ffc600:door opened (if > 2.0)" \
"AREA:no_water#eaeaea" \
"AREA:water_meter#086ca4:water usage detected (if > 1.0)" \
"AREA:no_ir#eaeaea" \
"AREA:ir_sensor#b93425:indoor movements detected (if > 0.0)"

result="$?"

if [[ "$result" -eq "0" ]]; then
echo  "<img src=\"$grpath/counters.png\" alt=\"change in values of counters\">"
echo  "</br>"
echo  "<small>updated on `$LSMODTIME $grdir/counters.png`</small></br>"
else
echo  "</br>ups...server error... :((</br>"
fi

silent $RRDTOOL graph $grdir/indoor.png -a PNG \
--title="Room temperatures for past $Period" --vertical-label "Deg C" \
--end $End --start $Start --width 800 \
"DEF:outdoor=$dbdir/temperature-outdoor.rrd:value:AVERAGE" \
"CDEF:outdoor_scaled=outdoor,4,/,15,+" \
"DEF:central_room=$dbdir/temperature-central_room.rrd:value:AVERAGE" \
"DEF:bedroom=$dbdir/temperature-bedroom.rrd:value:AVERAGE" \
"DEF:maria_room=$dbdir/temperature-maria_room.rrd:value:AVERAGE" \
"DEF:ilia_room=$dbdir/temperature-ilia_room.rrd:value:AVERAGE" \
"DEF:guestroom=$dbdir/temperature-guestroom.rrd:value:AVERAGE" \
"LINE1:10" \
"AREA:5#F5D6D5::STACK" \
"AREA:5#E6FFFF::STACK" \
"AREA:8#F0F3A5::STACK" \
"HRULE:28#b93425" \
"LINE2:central_room#0400ff:Central_room:dashes=15,5,5,10:dash-offset=10" \
"GPRINT:central_room:LAST:\:%2.1lf" \
"LINE1:bedroom#cccccc:Bedroom" \
"GPRINT:bedroom:LAST:\:%2.1lf" \
"LINE1:maria_room#35b73d:Maria_room:dashes=5,15,5,10:dash-offset=5" \
"GPRINT:maria_room:LAST:\:%2.1lf" \
"LINE1:ilia_room#85b73d:Ilia_room" \
"GPRINT:ilia_room:LAST:\:%2.1lf" \
"LINE1:guestroom#ff00ff:Guestroom" \
"GPRINT:guestroom:LAST:\:%2.1lf" 
# \ "LINE2:outdoor_scaled#0400ff:Outdoor"

result="$?"

if [[ "$result" -eq "0" ]]; then
echo  "<img src=\"$grpath/indoor.png\" alt=\"room temperatures\">"
echo  "</br>"
echo  "<small>updated on `$LSMODTIME $grdir/indoor.png`</small></br>"
else
echo  "</br>ups...server error... :((</br>"
fi

silent $RRDTOOL graph $grdir/outdoor.png -a PNG \
--title="Outdoor temperature for past $Period" --vertical-label "Deg C" \
--end $End --start $Start --width 800 \
"DEF:outdoor=$dbdir/temperature-outdoor.rrd:value:AVERAGE" \
"HRULE:0#000000" \
"VDEF:outdoor_max=outdoor,MAXIMUM" \
"VDEF:outdoor_min=outdoor,MINIMUM" \
"LINE2:outdoor#0400ff:Outdoor" \
"GPRINT:outdoor:AVERAGE:   Average\:%4.1lf"  \
"GPRINT:outdoor_min:   Minimum\:%4.1lf"  \
"GPRINT:outdoor_max:   Maximum\:%4.1lf" \
"GPRINT:outdoor:LAST:   Current\:%4.1lf\n"


result="$?"

if [[ "$result" -eq "0" ]]; then
echo  "<img src=\"$grpath/outdoor.png\" alt=\"outdoor temperatures\">"
echo  "</br>"
echo  "<small>updated on `$LSMODTIME $grdir/outdoor.png`</small></br>"
else
echo  "</br>ups...server error... :((</br>"
fi

silent $RRDTOOL graph $grdir/heatpump.png -a PNG \
--title="Operations of Heat pump & Ventillation unit for past $Period" \
--vertical-label "Operation time, %" \
--end $End --start $Start --width 800 \
"DEF:valve=$dbdir/digt_in-E7XXXX_b.rrd:value:AVERAGE" \
"DEF:pump=$dbdir/digt_in-hpump_brine_circ.rrd:value:AVERAGE" \
"DEF:vent=$dbdir/digt_in-ventillation_switch.rrd:value:AVERAGE" \
"DEF:circ=$dbdir/digt_in-hpump_heating_circ.rrd:value:AVERAGE" \
"DEF:brine_in=$dbdir/temperature-hpump_brine_in.rrd:value:AVERAGE" \
"DEF:brine_out=$dbdir/temperature-hpump_brine_out.rrd:value:AVERAGE" \
"DEF:supply=$dbdir/temperature-hpump_heat_supply.rrd:value:AVERAGE" \
"DEF:return=$dbdir/temperature-hpump_heat_return.rrd:value:AVERAGE" \
"CDEF:brine=brine_in,brine_out,-" \
"CDEF:heat=supply,return,-" \
"CDEF:pump_on=pump,100,*" \
"CDEF:vent_on=vent,100,*" \
"CDEF:vent_on_scaled=vent_on,-1,*" \
"CDEF:circ_on=circ,100,*" \
"CDEF:valve_on=valve,100,*" \
"CDEF:hotwater=pump,valve,pump_on,0,IF,0,IF" \
"CDEF:househeat=valve,0,pump,pump_on,0,IF,IF" \
"CDEF:brine_scaled=brine,20,*" \
"CDEF:brine_adjusted=brine,pump,*" \
"VDEF:brine_av=brine_adjusted,AVERAGE" \
"VDEF:brine_max=brine_adjusted,MAXIMUM" \
"CDEF:heat_scaled=heat,5,*" \
"CDEF:heat_adjusted=heat,pump,*" \
"VDEF:heat_av=heat_adjusted,AVERAGE" \
"VDEF:heat_max=heat_adjusted,MAXIMUM" \
"VDEF:circ_pct=circ_on,AVERAGE" \
"VDEF:valve_pct=hotwater,AVERAGE" \
"VDEF:pump_pct=pump_on,AVERAGE" \
"VDEF:househeat_pct=househeat,AVERAGE" \
"VDEF:vent_pct=vent_on,AVERAGE" \
"AREA:circ_on#FFFFE4:circullation pump" \
"GPRINT:circ_pct:(%2.0lf%% av.)" \
"LINE1:valve_on#CE6905:3-way valve in \"hotwater\" position\n" \
"AREA:househeat#C0483B:house heating" \
"GPRINT:househeat_pct:(%3.1lf%% av.)   " \
"AREA:hotwater#FF9933:water heating" \
"GPRINT:hotwater:AVERAGE:(%3.1lf%% av.)" \
"LINE2:pump_on#C048FF:compressor" \
"GPRINT:pump_pct:(%3.1lf%% av.)" \
"TEXTALIGN:left" \
"AREA:vent_on_scaled#B8D4FF:ventillation" \
"GPRINT:vent_pct:(%2.0lf%% av.)\n"  \
"LINE1:0#000A00" \
"LINE1:-50" \
"LINE1:brine_scaled#0400FF: brine in-out temperature drop - scaled 200%:STACK" \
"GPRINT:brine_av:(Av.\:%-4.2lf" \
"GPRINT:brine_max:Max\:%-4.2lf C)"  \
"LINE1:-50#FF05FF" \
"AREA:heat_scaled#C334:heat supply-return temperature drop - scaled 50%:STACK" \
"GPRINT:heat_av:(Av.\:%-4.2lf" \
"GPRINT:heat_max:Max\:%-4.2lf C)"  \
--right-axis "0.1:5" \
--right-axis-label "temp.drop, Deg C"

if [[ "$result" -eq "0" ]]; then
echo  "<img src=\"$grpath/heatpump.png\" alt=\"heat pump operations\">"
echo  "</br>"
echo  "<small>updated on `$LSMODTIME $grdir/heatpump.png`</small></br>"
else
echo  "</br>ups...server error... :((</br>"
fi

silent $RRDTOOL graph $grdir/heatloops.png -a PNG --width 800 \
--title="\"Input-return\" temperature drop of heating loops for past $Period" \
--vertical-label "Deg C" \
--end $End --start $Start \
--right-axis "-1:0" \
--right-axis-label "Deg C" \
"DEF:rdsupply=$dbdir/temperature-heat_rdside_supply.rrd:value:AVERAGE" \
"DEF:guest=$dbdir/temperature-heat_guest_room.rrd:value:AVERAGE" \
"DEF:iliya=$dbdir/temperature-heat_iliya_room.rrd:value:AVERAGE" \
"DEF:maria=$dbdir/temperature-heat_maria_room.rrd:value:AVERAGE" \
"DEF:entrance=$dbdir/temperature-heat_entrance_hall.rrd:value:AVERAGE" \
"CDEF:guestroom=rdsupply,guest,-" \
"CDEF:iliya_room=rdsupply,iliya,-" \
"CDEF:maria_room=rdsupply,maria,-" \
"CDEF:entrance_hall=rdsupply,entrance,-" \
"DEF:lksupply=$dbdir/temperature-heat_lkside_supply.rrd:value:AVERAGE" \
"DEF:bed=$dbdir/temperature-heat_bedroom.rrd:value:AVERAGE" \
"DEF:central_l=$dbdir/temperature-heat_centralroom_l.rrd:value:AVERAGE" \
"DEF:central_r=$dbdir/temperature-heat_centralroom_r.rrd:value:AVERAGE" \
"DEF:sauna=$dbdir/temperature-heat_sauna_zone.rrd:value:AVERAGE" \
"DEF:supply=$dbdir/temperature-hpump_heat_supply.rrd:value:AVERAGE" \
"DEF:return=$dbdir/temperature-hpump_heat_return.rrd:value:AVERAGE" \
"CDEF:bedroom=lksupply,bed,-,-1,*" \
"CDEF:central_room=lksupply,central_l,central_r,+,0.5,*,-,-1,*" \
"CDEF:sauna_zone=lksupply,sauna,-,-1,*" \
"CDEF:heat_pump=supply,return,-" \
"CDEF:inv_heat_pump=supply,return,-,-1,*" \
"AREA:heat_pump#f2f79c:all_loops " \
"AREA:inv_heat_pump#f2f79c" \
"LINE3:maria_room#0400ff:maria_room" \
"LINE2:entrance_hall#777777:entrance_hall" \
"LINE1:guestroom#000000:guest_room" \
"LINE1:iliya_room#ff7700:iliya_room" \
"LINE3:bedroom#b93425:bed_room" \
"LINE2:central_room#007700:central_room" \
"LINE1:sauna_zone#00ff00:sauna_zone"

if [[ "$result" -eq "0" ]]; then
echo  "<img src=\"$grpath/heatloops.png\" alt=\"heating loop temperature drops\">"
echo  "</br>"
echo  "<small>updated on `$LSMODTIME $grdir/heatloops.png`</small></br>"
else
echo  "</br>ups...server error... :((</br>"
fi

if [ "$header" != "no" ]; then
echo  "</body>"
echo  "</html>"
fi
