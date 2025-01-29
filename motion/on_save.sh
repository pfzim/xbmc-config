#!/bin/sh

cam_id=$1
snapshot_file=$2

trap "rm -f '${snapshot_file}'" 1 2 3 8 9 15

umask 0011

(
  if ! flock -x -n 9 ; then
    rm -f "${snapshot_file}"
    exit 0
  fi

  if [ -e /opt/motion/flags/flag_cam_${cam_id}_event_save.disable -a ! \( -e /tmp/on_snapshot_camera${cam_id}.conf -o -e /opt/motion/flags/flag_cam_${cam_id}_event_save.once \) ] ; then
    rm -f "${snapshot_file}"
    exit 0
  fi

  . /opt/motion/config.conf

  ut=`date +%s`
  [ -f /tmp/on_save_${cam_id}.last ] && las=`cat /tmp/on_save_${cam_id}.last` || las=0
  dif=$((ut - las))

  # 3 seconds interval between shots

  if [ $dif -gt 3 ]; then
    echo $ut > /tmp/on_save_${cam_id}.last

    #mailsend -smtp ${MAIL_SMTP} -port ${MAIL_PORT} -f "${MAIL_ADDR}" -t "${MAIL_LOGIN}@yandex.ru" -starttls -auth-plain -user ${MAIL_LOGIN} -pass ${MAIL_PASS} -sub "Motion detected" -attach "${cam_id},image/jpeg,a"

    ic=`echo -e "\xF0\x9F\x92\xBE"`
    #wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${ic} Save photo ${cam_id}"
    #curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "photo=@${snapshot_file}" -F "caption=${ic} Save photo ${snapshot_file}"
    curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "document=@${snapshot_file}" -F "caption=${ic} ${SYS_NAME} Save photo ${snapshot_file}"

    # Manual snapshot required
    if [ -e /tmp/on_snapshot_camera${cam_id}.conf ] ; then
      rm -f /tmp/on_snapshot_camera${cam_id}.conf
    # First 10 shots required
    elif [ -e /opt/motion/flags/flag_cam_${cam_id}_event_save.once ] ; then
      shots=`cat /opt/motion/flags/flag_cam_${cam_id}_event_save.once` || shots=10
      shots=$((shots - 1))
      if [ $shots -gt 0 ] ; then
        echo $shots > /opt/motion/flags/flag_cam_${cam_id}_event_save.once
      else
        rm -f /opt/motion/flags/flag_cam_${cam_id}_event_save.once
      fi
    fi
  fi

  rm -f "${snapshot_file}"

) 9> /tmp/on_save_${cam_id}.lock
