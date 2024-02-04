#!/bin/sh

start-stop-daemon --start --exec /usr/bin/dbus-daemon -- --system
start-stop-daemon --start --exec /usr/sbin/NetworkManager
start-stop-daemon --start --exec /usr/libexec/elogind/elogind -- -D
start-stop-daemon --start --exec /usr/sbin/i2pd -- --daemon

sleep infinity
