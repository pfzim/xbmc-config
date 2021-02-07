#!/bin/sh

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_event_start_${1}.last` || ls=0
  dif=$((ut - ls))
  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_event_start_${1}.last
    dt=`date`
    ic=`echo -e "\xE2\x9A\xA0"`
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${ic} Event start at ${dt}&disable_notification=true"
  fi

) 9> /tmp/on_event_start_${1}.lock
