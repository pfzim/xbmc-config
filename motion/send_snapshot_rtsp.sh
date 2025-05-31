#!/bin/sh

# ./send_snapshot_rtsp.sh -i event_id rtsp_url

event_id='common'
url=''

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
    -i|--id)
      event_id=$2
      shift 2
      ;;
    *)
      url=$1
      shift
    ;;
  esac
done

[ -e "/opt/motion/flags/flag_${event_id}.disable" ] && exit 0

. /opt/motion/config.conf

ic=`echo -e "\xF0\x9F\x92\xBE"`
ffmpeg -hide_banner -loglevel error -nostats -rtsp_transport tcp -y -i "$url" -vframes 1 /tmp/rtsp_snapshot.jpg
curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "document=@/tmp/rtsp_snapshot.jpg" -F "caption=${ic} ${SYS_NAME} RTSP snapshot"

rm -f "/tmp/rtsp_snapshot.jpg"
