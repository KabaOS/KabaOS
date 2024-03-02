#!/bin/ash

exec &> /dev/null

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

mount -t tmpfs tmpfs /mnt/tmpfs

while true; do
    # Mount the root filesystem.
    for i in $(blkid | cut -d':' -f1); do
        # Some ISO9660 magic to get the creation date and match it with the date we have
        if [ "$(dd if=$i bs=1 skip=33581 count=16)" = "$(cat /proc/cmdline | cut -f2 -d' ' | cut -c 6- | tr -d '-')" ]; then
            mount "${i}3" /mnt/iso

            if [ "$(/usr/bin/sha256sum /mnt/iso/alpine.zst.squashfs | cut -c-64)" = "$(cat /proc/cmdline | cut -f3 -d' ' | cut -c 6-)" ]; then
                mount -o loop /mnt/iso/alpine.zst.squashfs /mnt/squashfs
                mkdir /mnt/tmpfs/upper /mnt/tmpfs/root
                mount -t overlay overlay -o lowerdir=/mnt/squashfs,upperdir=/mnt/tmpfs/upper,workdir=/mnt/tmpfs/root /mnt/tmpfs/root
                mkdir -p /mnt/tmpfs/root/lib/firmware
                cp -r /lib/firmware/. /mnt/tmpfs/root/lib/firmware/
                echo "${i}" > /mnt/tmpfs/root/var/root

                # Clean up.
                umount /proc
                umount /sys
                umount /dev

                # Boot the real thing.
                exec switch_root /mnt/tmpfs/root /sbin/init
            fi

            umount /mnt/iso
        fi
    done
done
