#!/bin/sh

. /opt/motion/config.conf

filecontent=`cat /mnt/data/mounted`

if [ "$filecontent" != "mounted" ] ; then
  wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} HDD check failed. Is not mounted"
fi
