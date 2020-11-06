#!/bin/sh

[ -f /etc/motion/conf.d/camera$1.conf ] || exit 1

rm -f /etc/motion/conf.d/camera$1.conf

#systemctl restart motion

pid=`pidof -s motion`
if [ $? -eq 0 ] ; then
  kill -s 1 $pid
  exit 0
fi

exit 0
