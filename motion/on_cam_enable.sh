#!/bin/sh

[ -f /etc/motion/conf.avail/camera$1.conf ] || exit 1

ln -s /etc/motion/conf.avail/camera$1.conf /etc/motion/conf.d/

#systemctl restart motion

pid=`pidof -s motion`
if [ $? -eq 0 ] ; then
  kill -s 1 $pid
  exit 0
fi

exit 1
