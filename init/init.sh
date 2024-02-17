#!/bin/sh

mount -o nosuid,nodev,noexec,hidepid=2 -t proc none /proc
mount -t sysfs none /sys

iptables-restore < /root/iptables.rules

openrc -qq
hostname OS

agetty -cJn -a Cloak tty1 linux
