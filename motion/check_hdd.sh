#!/bin/sh

. /opt/motion/config.conf

if [ ! -e /dev/ttyACM0 ] ; then
  wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Zigbee coordinator device failed!"
fi

if [ ! -e /opt/motion/flags/flag_no_check_hdd.enabled ] ; then
  filecontent=`cat /mnt/data/mounted`

  if [ "$filecontent" != "mounted" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} HDD check failed. Is not mounted. Starting fsck"
    sudo fsck -fy /dev/sda1
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} fsck done"
  fi
fi

if [ ! -e /opt/motion/flags/flag_no_check_motion_service.enabled ] ; then
  motion_state=`systemctl show motion.service -p ActiveState`
  if [ "$motion_state" != "ActiveState=active" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Motion service is stopped"
    sudo systemctl stop motion
    sudo systemctl start motion
  fi
fi
