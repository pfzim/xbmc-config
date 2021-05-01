#!/bin/sh

# ./on_send_sms.sh event_id message_text force

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  [ "${3}" != "force" -a ! -e /opt/motion/flags/flag_sms_${1}.enabled ] && exit 0

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_send_sms_${1}.last` || ls=0
  dif=$((ut - ls))

  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_send_sms_${1}.last
    dt=`date '+%d.%m.%Y %T'`
    echo -ne "AT+CMGF=1\\r\\nAT+CMGS=\"${SMS_PHONE}\"\\r\\n${2}\\x1a" > /dev/ttyUSB0
  fi

) 9> /tmp/on_send_sms_${1}.lock
