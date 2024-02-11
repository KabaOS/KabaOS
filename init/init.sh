#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

openrc

/bin/hostname OS
agetty -a Cloak tty1 linux

/bin/sh

sleep infinity
