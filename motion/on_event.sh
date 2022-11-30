#!/bin/sh

# ./on_event.sh event_id camera_id message_text force false

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  [ "${4}" != "force" -a -e /opt/motion/flags/cam_${2}_events.disable -a ! -e /opt/motion/flags/cam_${2}_event_${1}.once ] && exit 0

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_event_${1}_${2}.last` || ls=0
  dif=$((ut - ls))
  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_event_${1}_${2}.last
    dt=`date '+%d.%m.%Y %T'`
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${3} at ${dt}&disable_notification=${5}"
    #curl -s -o /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${3} at ${dt}&disable_notification=${5}"

    [ -e /opt/motion/flags/cam_${2}_event_${1}.once ] && rm -f /opt/motion/flags/cam_${2}_event_${1}.once
  fi

) 9> /tmp/on_event_${1}_${2}.lock
