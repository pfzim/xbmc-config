#!/bin/sh

. /opt/motion/config.conf

ip a | mailsend -smtp ${MAIL_SMTP} -port ${MAIL_PORT} -f "${MAIL_ADDR}" -t "${MAIL_ADDR}" -starttls -auth-plain -user ${MAIL_LOGIN} -pass ${MAIL_PASS} -sub "${SYS_NAME} Info"
wget -q -O /dev/null "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${BOT_CHAT_ID}&text=${SYS_NAME} Send info to mail"

