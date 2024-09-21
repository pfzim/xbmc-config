#!/bin/sh

#touch /opt/motion/flags/cam_${1}_events.disable || exit 1

touch /opt/motion/flags/flag_cam_${1}_event_motion.disable
touch /opt/motion/flags/flag_cam_${1}_event_start.disable
touch /opt/motion/flags/flag_cam_${1}_event_stop.disable
touch /opt/motion/flags/flag_cam_${1}_event_save.disable

exit 0
