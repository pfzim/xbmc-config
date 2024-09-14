#!/bin/sh

. /opt/motion/config.conf

if [ ! -e /opt/motion/flags/flag_check_zigbee.disabled ] ; then
  if [ ! -e /dev/ttyACM0 ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Zigbee coordinator device failed!"
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_internet.disabled ] ; then
  cnt=`cat /tmp/no_internet.count` || cnt=0

  if ! ping -c 1 8.8.8.8 >/dev/null 2>&1 ; then
    if ! ping -c 1 77.88.8.8 >/dev/null 2>&1 ; then
      cnt=$((cnt + 1))
      if [ $cnt -gt 3 ] ; then
        reboot
      else
        echo $cnt > /tmp/no_internet.count
      fi
    fi
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_hdd.disabled ] ; then
  filecontent=`cat /mnt/data/mounted`

  if [ "$filecontent" != "mounted" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} HDD check failed. Is not mounted. Starting fsck"
    sudo fsck -fy /dev/sda1
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} fsck done"
  fi
fi

if [ ! -e /opt/motion/flags/flag_check_motion_service.disabled ] ; then
  motion_state=`systemctl show motion.service -p ActiveState`
  if [ "$motion_state" != "ActiveState=active" ] ; then
    wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Motion service is stopped"
    sudo systemctl stop motion
    sudo systemctl start motion
  fi
fi
