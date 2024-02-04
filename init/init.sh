#!/bin/sh

/usr/sbin/i2pd &
dbus-launch gnome-session &

while true; do sleep 60; done
