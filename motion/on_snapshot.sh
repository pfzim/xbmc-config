#!/bin/sh


pid=`pidof -s motion`

if [ $? -eq 0 ] ; then
  kill -s 14 $pid
  exit 0
fi

exit 1
