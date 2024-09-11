#!/bin/sh

/opt/motion/send_event.sh -f -i reboot "REBOOT"
reboot -d 60

