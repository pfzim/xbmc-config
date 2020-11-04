#!/bin/sh

[ -f /etc/motion/conf.avail/camera$1.conf ] || exit 1

ln -s /etc/motion/conf.avail/camera$1.conf /etc/motion/conf.d/
systemctl restart motion

exit 0
