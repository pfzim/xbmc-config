#!/bin/sh

systemctl start motion

/opt/motion/on_flag_clear.sh check_motion_service.disabled
/opt/motion/send_event.sh -q -f -i motion_start "Motion service started"
