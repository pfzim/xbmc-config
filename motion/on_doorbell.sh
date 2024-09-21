#!/bin/sh

/opt/motion/send_snapshot_rtsp.sh "rtsp://user0:password1@10.1.2.3/cam/realmonitor?channel=1&subtype=0"
/opt/motion/send_event.sh -f -i doorbell "Doorbell button pushed"

#exit ${exit_code}
