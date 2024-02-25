#!/bin/busybox sh

exec &> /dev/null

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Mount the root filesystem.
for i in $(blkid | cut -d':' -f1); do
    # Some ISO9660 magic to get the creation date and match it with the date we have
    if [ "$(dd if=$i bs=1 skip=33581 count=16)" = "$(cat /proc/cmdline | cut -f2 -d' ' | cut -c 6- | tr -d '-')" ]; then
        mount "${i}3" /mnt/iso
        mount -t tmpfs tmpfs /mnt/root

        cd /mnt/root
        cat /mnt/iso/alpine.cpio.zst | zstd -d | cpio -i
        cd

        # Clean up.
        umount /proc
        umount /sys
        umount /dev

        # Boot the real thing.
        exec switch_root /mnt/root /sbin/init
    fi
done

/bin/sh