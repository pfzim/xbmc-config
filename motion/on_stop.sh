#!/bin/sh

. /opt/motion/config.conf

/opt/motion/on_flag_set.sh no_check_motion_service

systemctl stop motion
wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Motion service stopped"

