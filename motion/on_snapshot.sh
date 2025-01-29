#!/bin/sh

umask 0011

for fn in /etc/motion/conf.d/*.conf
do
  if [ -f $fn ] ; then
    fn=`basename $fn`
    touch /tmp/on_snapshot_${fn}
    chown motion:motion /tmp/on_snapshot_${fn}
  fi
done

exit_code=1
pid=`pidof -s motion`

if [ $? -eq 0 ] ; then
  kill -s 14 $pid
  exit_code=0
fi

/opt/motion/send_snapshot_rtsp.sh "rtsp://10.1.2.1/cam/realmonitor?channel=1&subtype=0"
/opt/motion/send_snapshot_rtsp.sh "rtsp://10.1.2.2/live/ch00_1"

exit ${exit_code}
