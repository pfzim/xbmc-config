#!/bin/sh

#touch /opt/motion/flags/cam_${1}_events.disable || exit 1

touch /opt/motion/flags/flag_cam_${1}_event_motion.disabled
touch /opt/motion/flags/flag_cam_${1}_event_start.disabled
touch /opt/motion/flags/flag_cam_${1}_event_stop.disabled
touch /opt/motion/flags/flag_cam_${1}_event_save.disabled

exit 0
