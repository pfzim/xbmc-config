#!/bin/sh

trap "rm -f '$2'" 1 2 3 8 9 15

(
  if ! flock -x -n 9 ; then
    rm -f "$2"
    exit 0
  fi

  if [ -e /tmp/cam_${1}_events.disable -a ! -e /tmp/on_snapshot_camera${1}.conf ] ; then
    rm -f "$2"
    exit 0
  fi

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_save_$1.last` || ls=0
  dif=$((ut - ls))

  if [ $dif -gt 3 ]; then
    echo $ut > /tmp/on_save_$1.last

    #mailsend -smtp ${MAIL_SMTP} -port ${MAIL_PORT} -f "${MAIL_ADDR}" -t "${MAIL_LOGIN}@yandex.ru" -starttls -auth-plain -user ${MAIL_LOGIN} -pass ${MAIL_PASS} -sub "Motion detected" -attach "$1,image/jpeg,a"

    ic=`echo -e "\xF0\x9F\x92\xBE"`
    #wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=$ic Save photo $1"
    curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "photo=@$2" -F "caption=$ic Save photo $2"
  fi

  rm -f "$2"
  [ -e /tmp/on_snapshot_camera${1}.conf ] && rm -f /tmp/on_snapshot_camera${1}.conf

) 9> /tmp/on_save_$1.lock
