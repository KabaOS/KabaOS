#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

iptables-restore < /root/iptables.rules

openrc -qq
hostname OS

agetty -cJn -a Cloak tty1 linux
