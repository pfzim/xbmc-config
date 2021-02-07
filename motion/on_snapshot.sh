#!/bin/sh

for fn in /etc/motion/conf.d/*.conf
do
  if [ -f $fn ] ; then
    fn=`basename ${fn}`
    touch /tmp/on_snapshot_${fn}
    chown motion:motion /tmp/on_snapshot_${fn}
  fi
done

pid=`pidof -s motion`

if [ $? -eq 0 ] ; then
  kill -s 14 ${pid}
  exit 0
fi

exit 1
