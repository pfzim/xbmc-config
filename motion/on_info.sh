#!/bin/sh

. /opt/motion/config.conf

ip a | mailsend -smtp ${MAIL_SMTP} -port ${MAIL_PORT} -f "${MAIL_ADDR}" -t "${MAIL_ADDR}" -starttls -auth-plain -user ${MAIL_LOGIN} -pass ${MAIL_PASS} -sub "${SYS_NAME} Info"
/opt/motion/send_event.sh -f -i info "Send info to mail"

