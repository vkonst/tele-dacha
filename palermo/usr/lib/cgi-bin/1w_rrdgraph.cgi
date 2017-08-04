#!/bin/bash
# Create 1w_sys@toledo charts and html page

dbdir="/var/lib/collectd/rrd/toledo/1w_sys"
grdir="/var/www/include"
grpath="/include"

RRDTOOL="/usr/bin/rrdtool"
LSMODTIME="/bin/date -r"

usage() {
 echo "usage: 1w_rrdgraph.cgi [[[-q QUERY_STRING] [-d folder] [--no_header]] | [-h]]"
 echo "Create 1w_sys@toledo charts and html page."
 echo
 echo "Optional arguments:"
 echo "-q, --query	- url query string"
 echo "-d, --dir	- folder to create charts in (default: $grdir)"
 echo "--no_header	- do not print html header (default: print html header)"
 echo "-h, --help	- display this help and exit"
 echo
 echo -n "Query string. "
 query_usage
}

query_usage() {
 echo 'rrd=RRD_ARCHIVE&dsname=DSNAME&amp;timespan=TIMESPAN&start=START&width=WIDTH&debug=yes|no'
 echo 'example: rrd=temperature-outdoor&start=now-300m&amp;timespan=4h'
 echo ""
 echo "RRD_ARCHIVE - name of rrd dbase file (without .rrd)"
 echo ""
 echo "All other parameters are optional:"
 echo "TIMESPAN - time period for charts in format of rrdgraph (default:36h)"
 echo "(examples: 1200s, 3h, 1d, 2w, 6m)"
 echo "START    - time to start charts in format of rrdgraph (defults: now-timespan)"
 echo "(examples: now,now-10800s,now-10h,now-2d,15:35,20150131)"
 echo "DSNAME   - rrd dsname (default: \"value\")"
 echo "WIDTH    - graph width in pixels"
 echo "debug    - print debug info in html code (default: no)"
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
echo  '<meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1">'
echo  "<title>vkhome-fi room temperatures</title>"
echo  "</head>"
echo  "<body>"
fi

rrds=`grep -oE "rrd=[a-zA-Z0-9+_\-]+"  <<< "$QUERY_STRING" | sed "s/rrd=//"`
i=0; unset RRD
while read -r line; do
 RRD[$i]="$line"
 ((i++))
done <<< "$rrds"

dsnames=`grep -oE "dsname=[a-zA-Z0-9+_\-]+"  <<< "$QUERY_STRING" | sed "s/dsname=//"`
i=0; unset DSNAME
while read -r line; do
 DSNAME[$i]="$line"
 if [ -z "${DSNAME[$i]}" ]; then DSNAME[$i]="value"; fi
 ((i++))
done <<< "$dsnames"

Timespan=`grep -oE "timespan=[a-zA-Z0-9]+"  <<< "$QUERY_STRING" | sed "s/timespan=//"`
if [ -z "$Timespan" ]; then Timespan="36h"; fi

starts=`grep -oE "start=[a-zA-Z0-9+:\-]+"  <<< "$QUERY_STRING" | sed "s/start=//"`
i=0; unset START; unset END
while read -r line; do
 START[$i]="$line"
 if [ -z "${START[$i]}" ]; then
  END[$i]="now"
  START[$i]="end-${Timespan}"
 else
  END[$i]="start+${Timespan}"
 fi
 ((i++))
done <<< "$starts"

Width=`grep -oE "width=[0-9]+"  <<< "$QUERY_STRING" | sed "s/width=//"`
if [ -z "$Width" ]; then Width="800"; fi

debug=`grep -oE "debug=[a-z]+"  <<< "$QUERY_STRING" | sed "s/debug=//"`
if [ ! "${debug}" = "yes" ]; then $debug=""; fi

i=0; for _a in ${RRD[@]}; do silent echo "rrd[$i]: ${_a}; "; ((i++)); done; silent echo "<br />"
i=0; for _a in ${DSNAME[@]}; do silent echo "dsname[$i]: ${_a}; "; ((i++)); done; silent echo "<br />"
i=0; for _a in ${START[@]}; do silent echo "start[$i]: ${_a}; "; ((i++)); done; silent echo "<br />"
i=0; for _a in ${END[@]}; do silent echo "end[$i]: ${_a}; "; ((i++)); done; silent echo "<br />"
silent echo "Timespan=$Timespan; Width=$Width; Debug=$debug<br />"

if [ -z "${RRD[0]}" ]; then

  echo "</br><b>1W rrd data bases:</b></br>"
  echo "<div style=\"overflow:auto;width:50%;height:50%;border:1px solid #ccc;\">"
  for _RRD in `ls $dbdir -1 | sed -e 's/\.rrd//'`; do
   echo "<a href=\"?rrd=${_RRD}&dsname=&timespan=${Timespan}&start=&width=&debug=\" target=\"_blank\">${_RRD}</a></br>"
  done
  echo "</div></br>"

  echo "URL parameters:</br>"
  echo "<pre>"
  query_usage
  echo "</pre>"

else

 i=0; for _rrd in ${RRD[@]}; do

   if [ -z "${DSNAME[$i]}" ]; then  DSNAME[$i]="${DSNAME[0]}"; fi 
   if [ -z "${START[$i]}" ];  then  START[$i]="${START[0]}"; fi 
   if [ -z "${END[$i]}" ];    then  END[$i]="${END[0]}"; fi 

   silent echo "rrd[$i]: ${_rrd}; dsname[$i]=${DSNAME[$i]}; start[$i]=${START[$i]}; end[$i]=${END[$i]}<br />"

   silent $RRDTOOL graph $grdir/tmp_graph${i}.png -a PNG \
   --title="${_rrd} (${DSNAME[$i]}). start:${START[$i]}, end:${END[$i]}" --vertical-label "${DSNAME[$i]}" \
   --end "${END[$i]}" --start "${START[$i]}" --width $Width -A \
   "DEF:value=$dbdir/${_rrd}.rrd:${DSNAME[$i]}:AVERAGE" \
   "DEF:min=$dbdir/${_rrd}.rrd:${DSNAME[$i]}:MIN" \
   "DEF:max=$dbdir/${_rrd}.rrd:${DSNAME[$i]}:MAX" \
   "VDEF:avg=value,AVERAGE" \
   "AREA:max#ff0000:maximum ${_rrd} (${DSNAME[$i]})\:" \
   "GPRINT:max:MAX:%5.2lf\l" \
   "AREA:min#04ff00:minimum ${_rrd} (${DSNAME[$i]})\:" \
   "GPRINT:min:MIN:%5.2lf\l"  \
   "LINE2:value#0400ff:average ${_rrd} (${DSNAME[$i]})\:" \
   "GPRINT:value:AVERAGE:%5.2lf"  \
   "GPRINT:value:MIN:%5.2lf" "GPRINT:value:MAX:%5.2lf" \
   "GPRINT:value:LAST:   Current\:%5.2lf\n" \
   "HRULE:0#000000" \
   "HRULE:avg#0400ff::dashes"

   result="$?"

   if [[ "$result" -eq "0" ]]; then
     echo  "<img src=\"$grpath/tmp_graph${i}.png\" alt=\"${_rrd}\">"
     echo  "</br>"
     echo  "<small>updated on `$LSMODTIME $grdir/tmp_graph${i}.png`</small></br>"
   else echo  "</br>ups...server error... :((</br>"; fi

   ((i++))
 done
fi

silent echo "**end<br />"

if [ "$header" != "no" ]; then
  echo  "</body>"
  echo  "</html>"
fi
