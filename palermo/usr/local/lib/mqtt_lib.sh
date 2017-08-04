#!/bin/bash
# mqtt tools for 1w-system

. /etc/mqtt/mqtt.conf

### Array to store mqtt message
declare -A msg
msg['text']=""		# message string (i.e. topic and payload: "vkhome-fi/sensors/temperature-outdoor 28.6 @1429627454")
msg['parsed']=""	# timestamp of message parsing (succesfully or fail)
msg['topic']=""		# message topic (ex: "vkhome-fi/sensors/temperature-outdoor")
msg['payload']=""	# message payload (i.e. value and timestamp: "28.6 @1429627454")
msg['value']=""		# message value (ex.: "28.6")
msg['time']=""		# message timestamp (ex.: "1429627454")
msg['prev_value']=""	# previous message value
msg['prev_time']=""	# previous message timestamp
msg['mon_value']=""	# "known" value to detect value change (used by mqtt_monitor_topic)
msg['mon_time']=""	# timestamp of first message with "known" value (used by mqtt_monitor_topic)

### mosquitto_pub and mosquitto_sub wrappers

function mqtt_pub() {
# Publish a message from STDIN with the mqtt broker
# $1 - [mandatory] subtopic to publish the message on ("default" if unset)
# $2 - [optional] parameters for mosquitto_pub
# STDIN - message to publish
[ -z "$1" ] && local subtopic="default" || local subtopic="$1"; shift
mosquitto_pub -h "${MQTT_broker}" -p "${MQTT_port}" -u "${MQTT_user}" -P "${MQTT_passw}" \
-t "${MQTT_root_topic}/${subtopic}" -l $@
[ "$?" -eq "0" ] && return 0 || return 1
}

function mqtt_pub_stamped_plaintext() {
# Publish a time stamped message with the value word from STDIN
# the payload (message string) has two words: value and then timestamp
# (ex.: 28.6 @1429627454)
# $1 - [mandatory] subtopic to publish the message on ("default" if unset)
# $2 - [optional] parameters for mosquitto_pub
# STDIN - value (one word) of the message to publish
local _msg="`cat`"
mqtt_pub $@ <<< "${_msg} @`date +%s`"
return $?
}

function mqtt_sub() {
# Subscribe to a topic and print mqtt messages on STDOUT
# $1 - [mandatory] subtopic to subscribe ("#" if unset)
# $2 - [optional] parameters for mosquitto_sub
[ -z "$1" ] && local subtopic="#" || local subtopic="$1"
shift

if [ "$1" == "--doNotDumpTopic" ]; then
  verbose=""; shift;
else
  verbose='-v';
fi;

mosquitto_sub -h "${MQTT_broker}" -p "${MQTT_port}" -u "${MQTT_user}" -P "${MQTT_passw}" -t "${MQTT_root_topic}/${subtopic}" ${verbose} $@
[ "$?" -eq "0" ] && return 0 || return 1
}

### Core functions

function mqtt_read_line () {
# Read one (only) mqtt message line on the subtopic and print it to STDOUT
# $1 - [mandatory] subtopic to read the message (line) from
# $2 - [optional] parameters for mosquitto_sub
local _line=
read -r _line < <(mqtt_sub $@)
if [ "$?" -eq "0" ]; then
  echo "${_line}"
  return 0
else
  msg['text']=""
 return 1
fi
}

function mqtt_read_messages () {
# Read mqtt messages on the subtopic and print every line to STDOUT
# $1 - [mandatory] subtopic to read the message (line) from
# $2 - [optional] parameters for mosquitto_sub
local _line=
while read -r _line; do 
  echo "${_line}"
done < <(mqtt_sub $@)
}

function mqtt_parse_message () {
# Parse mqtt message and store it to msg array
# $1 - [optional] mqtt message string
# if not set, msg['text'] used
msg['parsed']="@$(date +%s)"
[ -n "$1" ] && msg['text']="$@"
if [ -n "${msg['text']}" ]; then
  [ -n "${msg['value']}" ] && msg['prev_value']="${msg['value']}"
  [ -n "${msg['time']}" ] && msg['prev_time']="${msg['time']}"
  read -r msg['topic'] msg['payload'] <<< "${msg['text']}"
  ${_payload_parser}
  ${_on_parse_success}
  return 0
else
  msg['text']=""
  msg['topic']=""
  msg['payload']=""
  msg['value']=""
  msg['time']=""
  ${_on_parse_failure}
  return 1
fi
}

function _parse_as_plaintext () {
  msg['value']="${msg['payload']}"
  msg['time']="${msg['parsed']}"
}

function _parse_as_stamped_plaintext () {
# payload format: "28.6 @1429627454"
 read -r msg['value'] msg['time'] <<< "${msg['payload']}"
  #msg['sec_past']="${msg['parsed']/@/} - ${msg['time']/@/})"
}

function mqtt_dump_message () { 
# Parse mqtt message and dump msg array
# $1 - [optional] mqtt message string
# if not set, msg array used
[ -n "$1" ] && { mqtt_parse_message $@; [ "$?" -ne "0" ] && return 1; }
echo "text:      ${msg['text']}"
echo "parsed:    ${msg['parsed']} (`[ -n \"${msg['parsed']}\" ] && date -Is -d \"${msg['parsed']}\"`)"
echo "topic:     ${msg['topic']}"
echo "payload:   ${msg['payload']}"
echo "value:     ${msg['value']}"
echo "time:      ${msg['time']} (`[ -n \"${msg['time']}\" ] && date -Is -d \"${msg['time']}\"`)"
echo "prev_val:  ${msg['prev_value']}"
echo "prev_time: ${msg['prev_time']} (`[ -n \"${msg['prev_time']}\" ] && date -Is -d \"${msg['prev_time']}\"`)"
echo "mon_value: ${msg['mon_value']}"
echo "mon_time:  ${msg['mon_time']} (`[ -n \"${msg['mon_time']}\" ] && date -Is -d \"${msg['mon_time']}\"`)"
return 0
}

function decode_timestamp () {
  echo `[ -n \"${msg['time']}\" ] && date -Is -d \"${msg['time']}\"`
}

function mqtt_print_value() {
# Format and print a string with the value
# $1 - [mandatory] format string for printf (the "announcement" template)
# $2 - [optional] value to print (${msg['value']} by default)
local fmt="`grep -oE '%[^\ ]+' <<< \"$1\"`"
[ -z "$2" ] && local _value="${msg['value']}" || local _value="$2"
if [ -z "${fmt}" ]; then
 local _text="${1}${_value}"
else
 local _text=`printf "$1" "${_value}"`
fi
echo "${_text}"
}

function mqtt_read_topic () {
# Read mqtt messages on the subtopic, parse and process every message
# + (default processing action: print to STDOUT)
# $1 - [mandatory] topic to monitor + [optional] parameters for mosquitto_sub
# $2 - [mandatory] announcement to print out (format string for mqtt_print_value)
# $3 - [optional] value editor (forked child process) before further processing
# $4 - [optional] command to be forked in background if new message received and parsed
# $5 - [optional] command to be forked in background if new message filed to receive

local _line=
while read -r _line; do
  mqtt_parse_message ${_line}
  if [ "$?" -eq "0" ]; then
    # execute default value editor ${_on_msg_read} in parent process or fork command $3 in background
    [ -z "$3" ] && ${_on_msg_read} || msg['value']=$($3 <<< "${msg['value']}")
    # execute ${_on_read_success} in parent process or fork command $4 in background
    [ -z "$4" ] && ${_on_read_success} $2 || { $4 < <(mqtt_print_value "$2") > /dev/null 2>&1 & }
   else
    # execute ${_on_read_failure} in parent process or fork command $5 in background
    [ -z "$5" ] && ${_on_read_failure} || { $5 > /dev/null 2>&1 & }
   fi
done < <(mqtt_sub $1)
}

function mqtt_monitor_topic() {
# Read mqtt messages on a topic and print announcement to STDOUT if the value changes
# $1 - [mandatory] topic to monitor + [optional] parameters for mosquitto_sub
# $2 - [mandatory] announcement (format string for mqtt_print_value)
# $3 - [optional] minimum numerical change in value (by default values compared as text strings)
# $4 - [optional] initial value to compare with
# $5 - [optional] command to modify value before change analisys (forked child process)
# command: sed, tr, bc ... that gets value from STDIN and returns altered value to STDOUT
# see defined below: is_more_then, is_less_then, is_equal_to, on_or_off, above_or_below
# is_unchanged_for, is_unchanged_till, is_changed_before...
# $6 - [optional] command to be forked in background upon new message receive if it's value changed
# $7 - [optional] command to be forked in background upon new message receive if it's value unchanged
# Note _on_msg_read_msg, _on_val_changed and _on_val_unchanged function placeholders...

if [ -z "$4" ]; then
  msg['mon_time']=
  msg['mon_value']=
else
  msg['mon_time']="@`date +%s`"
  msg['mon_value']="$4"
fi

local _line=
while read -r _line; do

  mqtt_parse_message ${_line}
  if [ "$?" -eq "0" ]; then

    # execute default pre-processor (parent process) or a command (forked child process)
    [ -z "$5" ] && ${_on_msg_read} || msg['value']=$($5 <<< "${msg['value']}")

    if [ -n "${msg['mon_time']}" ]; then

      if _value_changed "${msg['value']}" "${msg['mon_value']}" "$3"; then

        # write changed value as "old"
        msg['mon_value']="${msg['value']}"
        msg['mon_time']="${msg['time']}"

        # do default action on value changed or fork callback in background if defined $6
        [ -z "$6" ] && ${_on_val_changed} "$2" || { $6 < <(mqtt_print_value "$2") > /dev/null 2>&1 & }

      else
        # do default action on value unchanged or fork callback in background if defined $7
        [ -z "$7" ] && ${_on_val_unchanged} || { $7 <<< "unchanged" > /dev/null 2>&1 & }
      fi

    else
      msg['mon_value']="${msg['value']}"
      msg['mon_time']="${msg['time']}"

    fi
  fi

done < <(mqtt_sub $1)
}

function mqtt_fork_monitor() {
# fork mqtt_monitor_topic (run as child process) in endless loop in background
# parameters are the same as for mqtt_monitor_topic
while true; do
 mqtt_monitor_topic $@
 sleep 60
done &
}

function mqtt_fork_reader() {
# fork mqtt_read_topic (run as child process) in endless loop in background
# parameters are the same as for mqtt_read_topic
while true; do
 mqtt_read_topic $@
 sleep 60
done &
}

### Pre-processors for mqtt_monitor_topic

function is_less_then() { local value="$(cat)"; bc <<< "$value<$1"; return "$?"; }
function is_more_then() { local value="$(cat)"; bc <<< "$value>$1"; return "$?"; }

function is_equal_to() { 
local value="$(cat)"
if [ -n "$2" ]; then
  echo "${value}<=(${1}+${2}) && ${value}>=(${1}-${2})" | bc
else
  [ "$value" = "$1" ] && echo 1 || echo 0
fi
return "$?"
}

function above_or_below() {
local value=$(cat)
[ "$(is_more_then $1 <<< "$value")" -eq "1" ] && echo above || echo below
}

function on_or_off() {
local value=$(cat)
[ "$value" -eq "1" ] && { echo on;  return 0; }
[ "$value" -eq "0" ] && { echo off; return 0; }
return 1
}

### Placeholders:

_on_val_changed="mqtt_print_value"
# placeholder: mqtt_print_value by default, redefine if needed
# called by mqtt_monitor_topic upon receive of new message if value changed

_on_val_unchanged=":"
# placeholder: "do nothing" by default, redefine if needed
# called by mqtt_monitor_topic upon receive of new message if value unchanged

_on_msg_read=":"
# placeholder: "do nothing" by default, redefine if needed
# called by mqtt_read_topic, mqtt_monitor_topic after new message parsed before any processing

_on_read_success="mqtt_print_value"
# placeholder: mqtt_print_value by default, redefine if needed
# called by mqtt_read_topic upon succsesfully parsed new message

_on_read_failure=":"
# placeholder: do nothing by default, redefine if needed
# called by mqtt_read_topic upon new message parsing failure

_payload_parser="_parse_as_stamped_plaintext"
# payload parsing function (default: _parse_as_stamped_plaintext)
# called by mqtt_parse_message if payload sucessfully read

_on_parse_success=":"
# placeholder: do nothing by default, redefine if needed
# called without parameters by mqtt_parse_message after successfull message parsing

_on_parse_failure=":"
# placeholder: do nothing by default, redefine if needed
# called without parameters by mqtt_parse_message if message parsing failed

### Service functions

function change_global_var () {
# variable named "$1" gets the value "$2"
declare -g -- "$1=$2"
}

function _abs_diff() {
local dif=`bc <<<"$1- $2"`; dif=${dif/-/}; echo $dif
}

function _numeric_value_changed() {
# 0 - if abs($1-$2) < $3
# 1 - if abs($1-$2) >= $3
local dif=`_abs_diff $1 $2`
if [ "`bc <<< \"$3>$dif\"`" -eq "0" ]; then
 #echo 1
 return 1
else
 #echo 0
 return 0
fi
}

function _text_value_changed() {
if [ "$1" = "$2" ]; then return 0; else return 1; fi
}

function _value_changed() {
# $1 and $2 - values to compare
# $3 - if set, min (numeric) change to detect, otherwise values compared as strings
# returns 1 - if value changed, 0 otherwise
if [ -z "$3" ]; then
 if _text_value_changed "$1" "$2"; then return 1; else return 0; fi
else
 if _numeric_value_changed "$1" "$2" "$3"; then return 1; else return 0; fi
fi
}

function mqtt_help() {
cat << "EOF"
### Parameters for mosquitto_pub and mosquitto_sub:
MQTT_broker, MQTT_port, MQTT_user, MQTT_passw
MQTT_root_topic

### Array to store mqtt message:
msg['text']       - message string (i.e. topic and payload: "vkhome-fi/sensors/temperature-outdoor 28.6 @1429627454")
msg['parsed']     - timestamp of message parsing (succesfully or failed)
msg['topic']	  - topic (ex: "vkhome-fi/sensors/temperature-outdoor")
msg['payload']	  - payload (i.e. value and timestamp: "28.6 @1429627454")
msg['value']	  - value (ex.: "28.6")
msg['time']	  - timestamp (ex.: "1429627454")
msg['prev_value'] - previous message value
msg['prev_time']  - previous message timestamp
msg['mon_value']  - "known" value to detect value change (used by mqtt_monitor_topic)
msg['mon_time']   - timestamp of first message with "known" value (used by mqtt_monitor_topic)

topic="$MQTT_root_topic/$subtopic"

### Functions:
mqtt_pub
# Publish a message from STDIN with the mqtt broker
# $1 - subtopic to publish the message on ("default" if unset)
# $2 - parameters for mosquitto_pub [optional]

mqtt_sub
# Subscribe to a topic and print mqtt messages on STDOUT
# $1 - [mandatory] subtopic to subscribe ("#" if unset)
# $2 - [optional] parameters for mosquitto_pub

mqtt_read_line
# Read one (only) mqtt message line on the subtopic and print it to STOUT
# $1 - [mandatory] subtopic to read the message from
# $2 - [optional] parameters for mosquitto_sub

mqtt_read_messages
# Read mqtt messages on the subtopic and print every line to STDOUT
# $1 - [mandatory] subtopic to read the message (line) from
# $2 - [optional] parameters for mosquitto_sub

mqtt_parse_message
# Parse mqtt message and store it to msg array
# $1 - [optional] mqtt message string
# if not set, msg['text'] used

mqtt_dump_message
# Parse mqtt message and dump msg array
# $1 - [optional] mqtt message string
# if not set, msg array used

mqtt_print_value
# Format and print a string with the value
# $1 - [mandatory] format string for printf (the "announcement" template)
# $2 - [optional] value to print (${msg['value']} by default)

mqtt_monitor_topic
# Read mqtt messages on a topic and print it to STDOUT whenever the message value changes
# $1 - [mandatory] subtopic to monitor + [optional] parameters for mosquitto_sub
# $2 - [mandatory] announcement for mqtt_print_value
# $3 - [optional] minimum numerical change in value (by default values compared as text strings)
# $4 - [optional] initial value to compare with
# $5 - [optional] value modificator (see below)
# $6 - [optional] command to be forked in background upon new message receive if it's value changed
# $7 - [optional] command to be forked in background upon new message receive if it's value unchanged
# NB: function placeholders (see below)
# NB: _on_msg_read_msg, _on_val_changed and _on_val_unchanged function placeholders...

mqtt_read_topic
# Read mqtt messages on the subtopic, parse and process every message
# + default processing action : print to STDOUT
# $1 - [mandatory] topic to monitor + [optional] parameters for mosquitto_sub
# $2 - [mandatory] announcement to print out (format string for mqtt_print_value)
# $3 - [optional] value editor (forked child process) before further processing
# $4 - [optional] command to be forked in background if new message received and parsed
# $5 - [optional] command to be forked in background if new message filed to receive

mqtt_fork_monitor
# fork mqtt_monitor_topic (run as child process) in endless loop in background
# parameters are the same as for mqtt_monitor_topic

mqtt_fork_reader
# fork mqtt_read_topic (run as child process) in endless loop in background
# parameters are the same as for mqtt_read_topic

# Value modificators (pre-processors)
# called by mqtt_monitor_topic upon receive of new message after the message parsed before value change detection
# gets parsed value to process in STDIN, returns altered value to STDOUT
# NB: called as forked child process - parent process variables avaliable for reading but can'be changed
# NB: external command (sed, tr, bc ... ) may be used
is_less_then
is_more_then
is_equal_to
above_or_below
on_or_off

# Placeholders for function name (command), redefined if needed
# called inside parent process - parent variables accessible for read/write

_on_val_changed	- action to execute if value changed detected
# called by mqtt_monitor_topic (params: $2) upon receive of new message if value changed
# mqtt_print_value by default

_on_val_unchanged - action to execute on value unchanged
# called by mqtt_monitor_topic (without params) upon receive of new message if value unchanged
# "do nothing"

_on_read_success - action to execute upon new message successfull read
# mqtt_print_value by default, redefine if needed
# called by mqtt_read_topic upon succsesfully parsed new message

_on_read_failure - action to execute upon new message read failure
# called by mqtt_read_topic upon new message parsing failure
# "do nothing"

_on_msg_read - action on message (line) read
# called by mqtt_read_topic, mqtt_monitor_topic (no params) after new message received
# + before any processing
# "do nothing"

_payload_parser 
# payload parser (function) called by mqtt_parse_message
# "_parse_as_stamped_plaintext", no parameters (msg array used)
# see: _parse_as_stamped_plaintext, _parse_as_plaintext

_on_parse_success
# action to execute by mqtt_parse_message upon successfull parsing of a message
# "do nothing", no parameters

_on_parse_failure
# action to execute by mqtt_parse_message upon message parsing failure
# "do nothing", no parameters

### Examples:

mqtt_parse_message "$(mqtt_read_line 'sensors/digt_in-hpump_brine_circ')"; \
mqtt_print_value 'The heat pump is %s.' | sed -r -e 's/1/on/' -e 's/0/off/'

while read -r message; do mqtt_parse_message "${message}"; mqtt_dump_message; done < <(mqtt_sub 'sensors/temperature-outdoor')
while read -r message; do mqtt_dump_message "${message}"; done < <(mqtt_read_messages 'sensors/temperature-outdoor')

mqtt_parse_message "$(mqtt_read_line 'sensors/temperature-hpump_heat_supply')"; mqtt_dump_message
mqtt_print_value 'Heat supply line temperature is %.1f celsius degrees'

mqtt_monitor_topic 'sensors/digt_in-hpump_brine_circ' 'heat pump compressor switched to' '' '1'
mqtt_monitor_topic 'sensors/temperature-outdoor' 'outdoor temperature is  %.0f celsius degrees' '1' '50'
mqtt_monitor_topic 'sensors/temperature-outdoor' 'outdoor temperature is %s zero' '' '' 'above_or_below 0'
mqtt_monitor_topic 'sensors/temperature-hpump_heat_supply' 'heat supply line temperature is  %.1f celsius degrees' '1' '10'
mqtt_monitor_topic 'sensors/count-entrance_doors' 'door has been opened %0.0s'
mqtt_monitor_topic 'sensors/temperature-hpump_heat_supply' \
 'heat supply line temperature is  %s 27 celsius degrees' '0.1' '50' 'above_or_below 27'
mqtt_monitor_topic 'sensors/digt_in-hpump_brine_circ' 'heat pump compressor switched' '' '' 'on_or_off'
mqtt_monitor_topic 'sensors/temperature-hpump_heat_supply' '' '' '' 'is_more_then 39'
mqtt_monitor_topic 'sensors/temperature-hpump_heat_supply' '' '' '' 'is_less_then 15'

mqtt_monitor_topic 'sensors/temperature-hpump_heat_supply' \
  'heat supply line temperature is %s 28 celsius degrees' '' '' 'above_or_below 28' './scripts/say_google.sh'

while true; do
 mqtt_monitor_topic 'sensors/digt_in-hpump_brine_circ' 'the heat pump switched ' '' '' 'on_or_off'
 sleep 60
done &

while true; do
 mqtt_monitor_topic 'sensors/digt_in-ventillation_switch' 'ventillation switched ' '' '' 'on_or_off'
 sleep 60
done &

while true; do
 mqtt_monitor_topic 'sensors/temperature-outdoor' 'outdoor-temperature is %.1f celsius degrees' '2'
 sleep 60
done &

while true; do
 mqtt_monitor_topic 'sensors/count-entrance_doors' 'the entrance door has been opened %0.0s'
 sleep 60
done &
EOF
}

#_not_yet_finished_function_value_changed() {
# $1 - new value (number, chars)
# $2 - old value (number, chars)
# $3 - how to compare values [optional]
#  "%value%=1" ("%value%=OFF") - "TRUE" if $1="1" ($1="OFF") and $2 is anythig else
#  "%value%>2.5" ("%value%<-3") - "TRUE" if $1>2.5 ($1<-3) and $2=<2.5 ($2
#  "%change%>2.5"("%vlue%<-7"
# if $3 not defined - returns $1=$2
#}

# function change_var () {
# echo "passed var name: $1"
# echo "$1 value: ${!1}"
# echo "new value to assign to $1: $2"
# declare -g -- "$1=$2"
# }
# the_var="undefined"; change_var "the_var" "defined"; echo $the_var
# passed var name: the_var
# the_var value: undefined
# new value to assign to the_var: defined
# defined
