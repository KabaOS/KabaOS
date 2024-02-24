#!/bin/sh

exec &> /dev/null

mount -o nosuid,nodev,noexec,hidepid=2 -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs dev /dev -o mode=0755,nosuid
mount -t tmpfs run /run -o nosuid,nodev,mode=0755

iptables-restore < /root/iptables.rules

rfkill block all
rfkill unblock wifi

mkdir -p /run/openrc
touch /run/openrc/softlevel
mkdir /run/dbus
ln -sf /var/run/dbus/system_bus_socket /run/dbus/system_bus_socket

openrc
hostname OS

agetty -cJn -a Cloak tty1 linux
