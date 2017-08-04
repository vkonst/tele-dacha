#!/bin/bash

readonly dbdir="/var/lib/collectd/rrd/toledo/1w_sys"
readonly RRDTOOL="/usr/bin/rrdtool"
readonly SCRIPT=$(basename $0)

usage() {
 echo "Usage: ${SCRIPT} - print 1w_sys temperauture data."
 echo
 echo "Mandatory parameters:"
 echo "-r, --rrd=RRD     -name of rrd-archive with temperature data"
 echo "    !! RRD must be defined either with -r(--rrd) or with -q(--query)"
 echo
 echo "Optional parameters:"
 echo "-s, --start=START - timestamp of data to begin from (defults: now-timespan)"
 echo "    (examples of START: now,now-10800s,now-10h,now-2d,15:35,20150131)"
 echo "-e, --end=END     - timestamp of data to stop at (defults: now)"
 echo "    (examples: now,now-10800s,now-10h,now-2d,15:35,20150131)"
 echo "-t, --timespan=T  - period of timestamps for data (default:24h)"
 echo "    (examples: 20m, 4h, 3d, 2w, 1y)"
 echo "-q, --query       - url query string (see explanations bellow)"
 echo "    (example: --query 'rrd=temperature_outdoor&start=20150501&end=20150518' )"
 echo "--no_html         - do not print html headers/tags (default: print html)"
 echo "--debug           - print debug information (default: do not print)"
 echo "-h, --help        - display this help and exit"
 echo
 echo "!! START,END,TIMESPAN may be set either with -s, -e, -t or with -q"
 echo
 echo "Query string:"
 echo "[rrd=RRD][&timespan=TIMESPAN][&start=START][&end=END][&debug=yes]"
 echo "(example: rrd=temperature_outdoor&timespan=4h )"
 echo "See above notes for explanations on parameters."
}

print_temp() {
# $1 - rrd [mandatory]
# $2 - start [optional, default: end-24h]
# $3 - end [optional, default: now]
${RRDTOOL} graph /tmp/del.me --end "${3:-now}" --start "${2:-end-24h}" \
 "DEF:avg_temp=${dbdir}/${1/.rrd/}.rrd:value:AVERAGE" \
 "DEF:min_temp=${dbdir}/${1/.rrd/}.rrd:value:MIN" \
 "DEF:max_temp=${dbdir}/${1/.rrd/}.rrd:value:MAX" \
 "CDEF:var_mint=avg_temp,min_temp,-" \
 "CDEF:var_maxt=max_temp,avg_temp,-" \
 "VDEF:avgtemp_fst=avg_temp,FIRST" \
 "VDEF:avgtemp_lst=avg_temp,LAST" \
 "VDEF:temp_min=min_temp,MINIMUM" \
 "VDEF:temp_max=max_temp,MAXIMUM" \
 "VDEF:avgtemp_sdv=avg_temp,STDEV" \
 "VDEF:varmint_sdv=var_mint,STDEV" \
 "VDEF:varmaxt_sdv=var_maxt,STDEV" \
 "PRINT:avg_temp:AVERAGE:average %5.2lf" \
 "PRINT:avgtemp_sdv:avgStDev %5.2lf" \
 "PRINT:varmint_sdv:minStDev %5.2lf" \
 "PRINT:varmaxt_sdv:maxStDev %5.2lf" \
 "PRINT:temp_min:minimum %5.2lf" \
 "PRINT:temp_max:maximum %5.2lf" \
 "PRINT:avgtemp_fst:first %5.2lf" \
 "PRINT:avgtemp_lst:last %5.2lf"
return $?
}

parse_params() {
[ -n "${debug}" ] && echo "*DEBUG* parse_params: $@"
for param in $(tr "&" "\n" <<< "$@"); do
 local name="${param%=*}"
 local value="${param#*=}"
 case "${name}" in
  rrd)      rrd="${value}" ;;
  start)    start="${value}" ;;
  end)      end="${value}" ;;
  timespan) timespan="${value}" ;;
  debug)    debug="${value}" ;;
  * )       return 1 ;;
 esac
done
return 0
}

check_params() {
if [ -z "${rrd}" ]; then 
 echo "Error: RRD is not specified" >&2 
 echo "Try \"${SCRIPT} --help\" for more info"
 return 1
fi
[ -z "${timespan}" ] && timespan='24h'
[ -z "${end}" ] && { [ -z "${start}" ] && end='now' || end="start+${timespan}"; }
[ -z "${start}" ] && start="end-${timespan}"
[ -n "${debug}" ] && echo "*DEBUG* check_params: rrd=${rrd}; start=${start}; end=${end}"
return 0
}

print_html_header() {
echo "Content-type: text/html"
echo
echo "<html><head><title>vkhome-fi ${rrd} statistics</title></head>"
echo "<body><pre>"
}

print_html_footer() {
echo "</pre></body>"
echo "</html>"
}

while [ "$1" != "" ]; do
 case $1 in
   -q | --query)
     shift
      QUERY_STRING="$1"
      ;;

   -r )
      shift
      rrd="$1"
      ;;

   --rrd=* )
      rrd=$(cut -d "=" -f 2 <<< "$1")
      ;;

   -s )
      shift
      start="$1"
      ;;

   --start=* )
      start=$(cut -d "=" -f 2 <<< "$1")
      ;;

   -e )
      shift
      end="$1"
      ;;

   --end=* )
      end=$(cut -d "=" -f 2 <<< "$1")
      ;;

   -t )
      shift
      timespan="$1"
      ;;

   --timespan=* )
      timespan=$(cut -d "=" -f 2 <<< "$1")
      ;;

   --no_html )
      html="no"
      ;;

   -h | --help )
      usage
      exit
      ;;

   --debug )
      debug="yes"
      ;;

    * )
      echo "unrecoqnized parameter $1" >&2
      echo "Try \"${SCRIPT} --help\" for more info"
      exit 1
      ;;
 esac
 shift
done

[ -z "${html}" ] && print_html_header

[ -n "${QUERY_STRING}" ] && if ! parse_params "${QUERY_STRING}"; then exit 1; fi
if ! check_params ; then exit 1; fi

print_temp ${rrd} ${start} ${end}
res="$?"

[ -z "${html}" ] && print_html_footer

exit ${res}
