#!/bin/busybox sh

mount -t proc none /proc
mount -t sysfs none /sys

# Mount the root filesystem.
mount -o rw $(findfs $(cat /proc/cmdline | cut -f2 -d' ' | cut -c 6-)) /mnt/iso
mount -t tmpfs tmpfs /mnt/root

cd /mnt/root
cat /mnt/iso/alpine.cpio.zst | zstd -d | cpio -i
cd

# Clean up.
umount /proc
umount /sys

# Boot the real thing.
exec switch_root /mnt/root /sbin/init
