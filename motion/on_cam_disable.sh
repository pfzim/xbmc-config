#!/bin/sh

[ -f /etc/motion/conf.d/camera$1.conf ] || exit 1

rm -f /etc/motion/conf.d/camera$1.conf
systemctl restart motion

exit 0
