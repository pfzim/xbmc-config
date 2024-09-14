#!/bin/sh

[ -f /opt/motion/send_event.sh ] && /opt/motion/send_event.sh -f -i login "User ${USER} login to system"
