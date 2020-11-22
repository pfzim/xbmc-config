#!/bin/sh

touch /opt/motion/flags/cam_${1}_events.disable || exit 1

exit 0
