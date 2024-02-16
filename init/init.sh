#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

openrc -qq
/bin/hostname OS

agetty -cJn -a Cloak tty1 linux
