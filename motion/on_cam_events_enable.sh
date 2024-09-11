#!/bin/sh

#rm -f /opt/motion/flags/cam_${1}_events.disable || exit 1

rm -f /opt/motion/flags/flag_cam_${1}_event_motion.disabled
rm -f /opt/motion/flags/flag_cam_${1}_event_start.disabled
rm -f /opt/motion/flags/flag_cam_${1}_event_stop.disabled
rm -f /opt/motion/flags/flag_cam_${1}_event_lost.disabled
rm -f /opt/motion/flags/flag_cam_${1}_event_found.disabled
rm -f /opt/motion/flags/flag_cam_${1}_event_save.disabled

exit 0
