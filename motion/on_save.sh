#!/bin/sh

trap "rm -f '$1'" 1 2 3 8 9 15

(
  if ! flock -x -n 9 ; then
    rm -f "$1"
    exit 0
  fi

  . /opt/motion/config.conf

  ut=`date +%s`
  ls=`cat /tmp/on_save.last` || ls=0
  dif=$((ut - ls))

  if [ $dif -gt 3 ]; then
    echo $ut > /tmp/on_save.last

    #mailsend -smtp ${MAIL_SMTP} -port ${MAIL_PORT} -f "${MAIL_ADDR}" -t "${MAIL_LOGIN}@yandex.ru" -starttls -auth-plain -user ${MAIL_LOGIN} -pass ${MAIL_PASS} -sub "Motion detected" -attach "$1,image/jpeg,a"

    ic=`echo -e "\xF0\x9F\x92\xBE"`
    #wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=$ic Save photo $1"
    curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "photo=@$1" -F "caption=$ic Save photo $1"
  fi

  rm -f "$1"

) 9> /tmp/on_save.lock
