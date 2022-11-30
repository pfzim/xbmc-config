#!/bin/sh

. /opt/motion/config.conf

ic=`echo -e "\xF0\x9F\x92\xBE"`
ffmpeg -hide_banner -loglevel error -nostats -rtsp_transport tcp -y -i "${1}" -vframes 1 /tmp/rtsp_snapshot.jpg
curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${BOT_CHAT_ID}" -H "Content-Type: multipart/form-data" -F "document=@/tmp/rtsp_snapshot.jpg" -F "caption=${ic} RTSP snapshot"

rm -f "/tmp/rtsp_snapshot.jpg"
