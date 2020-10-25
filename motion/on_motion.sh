#!/bin/sh

(
  if ! flock -x -n 9 ; then
    exit 0
  fi

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_motion.last` || ls=0
  dif=$((ut - ls))
  if [ $dif -gt 10 ]; then
    echo $ut > /tmp/on_motion.last
    dt=`date`
    ic=`echo -e "\xF0\x9F\x8F\x83"`
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=$ic Motion detected at $dt"
  fi

) 9> /tmp/on_motion.lock
