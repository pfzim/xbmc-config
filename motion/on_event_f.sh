#!/bin/sh

# ./on_event_f.sh event_id message_text force

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  [ "${3}" != "force" -a ! -e /opt/motion/flags/flag_${1}.enabled -a ! -e /opt/motion/flags/flag_${1}.once ] && exit 0

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_event_${1}.last` || ls=0
  dif=$((ut - ls))
  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_event_${1}.last
    dt=`date '+%d.%m.%Y %T'`
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${2} at ${dt}&disable_notification=true"

    if [ -e /opt/motion/flags/flag_${1}.once ] ; then
      count=`cat /opt/motion/flags/flag_${1}.once` || count=5
      count=$((shots - 1))
      if [ $count -gt 0 ] ; then
        echo $count > /opt/motion/flags/flag_${1}.once
      else
        rm -f /opt/motion/flags/flag_${1}.once
      fi
    fi
  fi

) 9> /tmp/on_event_${1}.lock
