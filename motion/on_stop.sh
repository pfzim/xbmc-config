#!/bin/sh

systemctl stop motion

/opt/motion/on_flag_set.sh check_motion_service.disabled
/opt/motion/send_event.sh -f -i motion_stop "Motion service stopped"
