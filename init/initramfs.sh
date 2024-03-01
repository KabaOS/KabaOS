#!/bin/ash

exec &> /dev/null

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

mount -t tmpfs tmpfs /mnt/root

while true; do
    # Mount the root filesystem.
    for i in $(blkid | cut -d':' -f1); do
        # Some ISO9660 magic to get the creation date and match it with the date we have
        if [ "$(dd if=$i bs=1 skip=33581 count=16)" = "$(cat /proc/cmdline | cut -f2 -d' ' | cut -c 6- | tr -d '-')" ]; then
            mount "${i}3" /mnt/iso

            if [ "$(/usr/bin/sha256sum /mnt/iso/alpine.cpio.zst | cut -c-64)" = "$(cat /proc/cmdline | cut -f3 -d' ' | cut -c 6-)" ]; then
                cd /mnt/root
                cat /mnt/iso/alpine.cpio.zst | zstd -d | cpio -i
                cd
                cp /bin/busybox /mnt/root/bin/busybox
                cp -r /lib/firmware/. /mnt/root/lib/firmware/

                # Clean up.
                umount /proc
                umount /sys
                umount /dev

                # Boot the real thing.
                exec switch_root /mnt/root /sbin/init
            fi

            umount /mnt/iso
        fi
    done
done
