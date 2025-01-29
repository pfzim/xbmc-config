#!/bin/sh

. /opt/motion/config.conf

umask 0011

if [ ! -e /opt/motion/flags/flag_check_zigbee.disable ] ; then
  if [ ! -e /dev/ttyACM0 ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Zigbee coordinator device failed!"
  fi

  /opt/motion/check_zigbee.py ${HA_TOKEN} ${ZIGBEE_ENTITY_ID}
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Zigbee device unavailable!"
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_internet.disable ] ; then
  [ -f /tmp/no_internet.count ] && cnt=`cat /tmp/no_internet.count` || cnt=0

  if ! ping -c 1 dns.google >/dev/null 2>&1 ; then
    if ! ping -c 1 dns.yandex.ru >/dev/null 2>&1 ; then
      cnt=$((cnt + 1))
      if [ $cnt -gt 3 ] ; then
        reboot
      else
        echo $cnt > /tmp/no_internet.count
      fi
    fi
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_hdd.disable ] ; then
  filecontent=`cat /mnt/data/mounted`

  if [ "$filecontent" != "mounted" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} HDD check failed. Is not mounted. Starting fsck"
    sudo fsck -fy /dev/sda1
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} fsck done"
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_motion_service.disable ] ; then
  motion_state=`systemctl show motion.service -p ActiveState`
  if [ "$motion_state" != "ActiveState=active" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Motion service is stopped"
    sudo systemctl stop motion
    sudo systemctl start motion
  fi
fi
