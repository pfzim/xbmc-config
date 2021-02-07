#!/bin/sh

# cmd.sh camera_id

touch /opt/motion/flags/cam_${1}_event_motion.once
touch /opt/motion/flags/cam_${1}_event_start.once
touch /opt/motion/flags/cam_${1}_event_stop.once
touch /opt/motion/flags/cam_${1}_event_lost.once
touch /opt/motion/flags/cam_${1}_event_found.once
touch /opt/motion/flags/cam_${1}_event_save.once

exit 0
