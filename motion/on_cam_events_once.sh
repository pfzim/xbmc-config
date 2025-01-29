#!/bin/sh

umask 0011

# cmd.sh camera_id

#touch /opt/motion/flags/cam_${1}_event_motion.once
#touch /opt/motion/flags/cam_${1}_event_start.once
#touch /opt/motion/flags/cam_${1}_event_stop.once
#touch /opt/motion/flags/cam_${1}_event_lost.once
#touch /opt/motion/flags/cam_${1}_event_found.once
#echo '5' >/opt/motion/flags/cam_${1}_event_save.once
#chmod a+rw /opt/motion/flags/cam_${1}_event_save.once

touch /opt/motion/flags/flag_cam_${1}_event_motion.once
touch /opt/motion/flags/flag_cam_${1}_event_start.once
touch /opt/motion/flags/flag_cam_${1}_event_stop.once
touch /opt/motion/flags/flag_cam_${1}_event_lost.once
touch /opt/motion/flags/flag_cam_${1}_event_found.once
echo '10' >/opt/motion/flags/flag_cam_${1}_event_save.once
chmod a+rw /opt/motion/flags/flag_cam_${1}_event_save.once

exit 0
