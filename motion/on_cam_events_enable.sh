#!/bin/sh

#rm -f /opt/motion/flags/cam_${1}_events.disable || exit 1

rm -f /opt/motion/flags/flag_cam_${1}_event_motion.disable
rm -f /opt/motion/flags/flag_cam_${1}_event_start.disable
rm -f /opt/motion/flags/flag_cam_${1}_event_stop.disable
rm -f /opt/motion/flags/flag_cam_${1}_event_lost.disable
rm -f /opt/motion/flags/flag_cam_${1}_event_found.disable
rm -f /opt/motion/flags/flag_cam_${1}_event_save.disable

exit 0
