#!/bin/sh

# ./on_ups_event.sh message_text

/opt/motion/send_event.sh -f -i ups_event "${1}"

/opt/motion/send_snapshot_rtsp.sh "rtsp://10.1.1.1/?user=admin&password=password&channel=1&stream=0"
/opt/motion/send_snapshot_rtsp.sh "rtsp://10.1.1.2/?user=admin&password=password&channel=1&stream=0"
