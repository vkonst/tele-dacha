#
# file: create_pid_or_exit_on_existing_pid.sh
# usage:
# . create_pid_or_exit_on_existing_pid.sh

script=${0##*/}

pidfile="/var/run/1w-sys/${0##*/}.pid"
if [ -f $pidfile ]; then
  echo "${script} is already running"
  exit 1
fi

trap "rm -f -- '$pidfile'" EXIT
echo $$ > "$pidfile"
