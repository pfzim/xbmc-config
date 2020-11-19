#!/bin/sh

# ./on_event.sh event_id camera_id message_text

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  [ -e /tmp/cam_${2}_events.disable ] && exit 0

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_event_${1}_${2}.last` || ls=0
  dif=$((ut - ls))
  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_event_${1}_${2}.last
    dt=`date '+%d.%m.%Y %T'`
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=$3 at $dt&disable_notification=true"
  fi

) 9> /tmp/on_event_${1}_${2}.lock
