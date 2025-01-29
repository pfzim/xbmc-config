#!/bin/sh

umask 0011
touch /opt/motion/flags/flag_${1} || exit 1

exit 0
