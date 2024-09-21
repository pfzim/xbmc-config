#!/bin/sh

sed -i "s/^\\s*movie_output\\s*off/movie_output on/" /etc/motion/motion.conf

#systemctl restart motion

pid=`pidof -s motion`
if [ $? -eq 0 ] ; then
  kill -s 1 $pid
  exit 0
fi

exit 1
