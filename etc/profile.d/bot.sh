#!/bin/sh

[ -f /opt/motion/send_event.sh ] && /opt/motion/send_event.sh -f -i logon "User ${USER} login to system"
