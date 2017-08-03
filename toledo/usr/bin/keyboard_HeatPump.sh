#!/bin/sh
# Emulate keypress on the keyboard of the Heat Pump
# Do not run unless you clear understand what you are doing!!!
# $1 - [up|down|left|right]

_1Wkeypress() {
# Switch "on" specified GPIO channel of the specified chip for 0.1 sec
# $1 - chip address on 1w-bus
# $2 - channel to toggle [1|2]
# $3 - time for chip to be toggle for (default 0.1s)

presstime=0.1
[ -n "$3" ] && presstime="$3"

local timestamp="`date -Iseconds`"

local state="`owread /uncached/${1}/sensed.BYTE`"
[ "$?" -ne "0" ] && { echo "Error: can not read $1" >&2; exit 1; }
echo "${timestamp};read;${1};PIO.BYTE;${state};(0)" | tr -d " "

timestamp="`date -Iseconds`"
owwrite "/uncached/${1}/PIO.BYTE" "${2}"
echo "${timestamp};write;$1;PIO.BYTE;$2;($?)"

usleep ${presstime}

timestamp="`date -Iseconds`"
owwrite "/uncached/${1}/PIO.BYTE" "0"
echo "${timestamp};write;$1;PIO.BYTE;0;($?)"

timestamp="`date -Iseconds`"
state="`owread /uncached/${1}/sensed.BYTE`"
[ "$?" -ne "0" ] && { echo "Error: can not read $1" >&2; exit 1; }
echo "${timestamp};read;${1};PIO.BYTE;${state};(0)" | tr -d " "
}

keypress() {
case $1 in
	up|UP)
        _1Wkeypress 3A.XXX4XXXXXXXX 2 ;;

	down|DOWN)
        _1Wkeypress 3A.XXX4XXXXXXXX 1 ;;

	left|LEFT)
        _1Wkeypress 3A.XXXAXXXXXXXX 1 ;;

	right|RIGHT)
        _1Wkeypress 3A.XXXAXXXXXXXX 2 ;;

        longleft|LONGLEFT)
        _1Wkeypress 3A.XXXAXXXXXXXX 1 5.0 ;;

	*)
	# printhelp > &2
	;;
esac
}

printhelp() {
echo "*** HIGH RISK OF BAD DAMAGE!"
echo "*** Do not use unless know for sure what you are doing!!!"
echo "Usage:"
echo "$0 up|left|down|right|longleft"
echo "$0 -i (for interactive mode)"
echo 'interactive mode keys: a|w|s|d|L, ctrl+c to exit'
}

processkeys() {
echo 'left:  a'
echo 'right: w'
echo 'down:  s'
echo 'right: d'
echo 'LongLeft: L'
echo 'q or ctrl+c to exit'
echo 'HIGH RISK OF BAD DAMAGE!'
echo 'Be sure you know exactly what are your doing!'
echo 'Leave time for system to react between keystrikes...'
while true; do
  read -n 1 -p "key> " char
  echo
  case $char in
  w) echo "key: up";    keypress up;;
  a) echo "key: left";  keypress left;;
  s) echo "key: down";  keypress down;;
  d) echo "key: right"; keypress right;;
  L) 
    read -n 1 -p "key: long left. Are you sure (Y/n)? > " char
    echo
    if [ "$char" == "Y" ]; then
      echo "key: longleft"
      keypress longleft
    fi
    ;;
  q) return 0;;
  *) echo 'unknown key. accepted: a|w|s|d|L; q or ctrl+c to exit';;
  esac
done
}

case $1 in
	-h|help)
	  printhelp
	  ;;
	-i)
	  processkeys
	  ;;
	up|UP|down|DOWN|left|LEFT|right|RIGHT|longleft|LONGLEFT)
	  keypress $1
	  ;;
	*)
	  printhelp
	  exit 1
	  ;;
esac


