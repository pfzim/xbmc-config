#!/bin/sh

# ./on_event_f.sh -f -s -i event_id message_text

event_id='common'
message=''
method='normal'
msg_type='telegram'
quiet='false'

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
    -f|--force)
      method='force'
      shift
      ;;
    -q|--quiet)
      quiet='true'
      shift
      ;;
    -s|--sms)
      msg_type='sms'
      shift
      ;;
    -i|--id)
      event_id=$2
      shift 2
      ;;
    *)
      message=$1
      shift
    ;;
  esac
done

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  [ -e "/opt/motion/flags/flag_${event_id}.disabled" -a ! -e "/opt/motion/flags/flag_${event_id}.once" ] && exit 0

  . /opt/motion/config.conf

  ut=`date +%s`
  [ -f "/tmp/send_event_${event_id}.last" ] && ls=`cat /tmp/send_event_${event_id}.last` || ls=0
  dif=$((ut - ls))
  if [ "${method}" = "force" -o $dif -gt 10 ] ; then
    echo $ut > /tmp/send_event_${event_id}.last
    dt=`date '+%d.%m.%Y %T'`
    if [ "${mgs_type}" = "sms" ] ; then
      echo -ne "AT+CMGF=1\\r\\nAT+CMGS=\"${SMS_PHONE}\"\\r\\n${message}\\x1a" > /dev/ttyUSB0
      #echo -ne "AT+CMGF=1\\nAT+CMGS=\"${SMS_PHONE}\"\\n${2}\\x1a" > /dev/ttyUSB0
    else
      wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} ${message} at ${dt}&disable_notification=${quiet}"
    fi

    if [ -f /opt/motion/flags/flag_${event_id}.once ] ; then
      count=`cat /opt/motion/flags/flag_${event_id}.once` || count=5
      count=$((shots - 1))
      if [ $count -gt 0 ] ; then
        echo $count > /opt/motion/flags/flag_${event_id}.once
      else
        rm -f /opt/motion/flags/flag_${event_id}.once
      fi
    fi
  fi

) 9> /tmp/send_event_${event_id}.lock
