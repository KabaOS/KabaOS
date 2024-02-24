#!/bin/sh

mount -o nosuid,nodev,noexec,hidepid=2 -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs dev /dev -o mode=0755,nosuid

iptables-restore < /root/iptables.rules

rfkill block all
rfkill unblock wifi

openrc
hostname OS

agetty -cJn -a Kaba tty1 linux
