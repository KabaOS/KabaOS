export CC="gcc"

export CFLAGS=-pipe -march=x86-64 -O2 -Wall
export CXXFLAGS=$(CFLAGS)
export LDFLAGS=-pipe -march=x86-64
export JOBS=$(shell nproc)

# VERSIONS

ALPINE=3.19.1
ALPINE_MINI=3.19

KERNEL=6.6.12
I2PD=2.49.0-r1
GNOME=45.0-r0
LIBREWOLF=122.0_p2-r0

.PHONY: build

all: download build

download: download_alpine download_kernel

build: create_img build_alpine finish_initramfs build_kernel cp_initramfs \
	build_iso

# ALPINE

download_alpine:
	mkdir -p build/alpine
	curl "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/releases/x86_64/alpine-minirootfs-$(ALPINE)-x86_64.tar.gz" -o build/alpine/alpine.tar.gz
	cd build/alpine/ && tar -xzf alpine.tar.gz
	rm build/alpine/alpine.tar.gz

build_alpine:
	mkdir -p build/alpine/
	umount build/alpine/proc |:
	umount build/alpine/dev |:
	umount build/alpine/sys |:
	mkdir -p build/alpine/proc
	mount -t proc none build/alpine/proc
	mkdir -p "build/alpine/dev"
	mount --bind "/dev" "build/alpine/dev"
	mount --make-private "build/alpine/dev"
	mkdir -p "build/alpine/sys"
	mount --bind "/sys" "build/alpine/sys"
	mount --make-private "build/alpine/sys"
	install -D -m 644 /etc/resolv.conf build/alpine/etc/resolv.conf
	echo -e "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/main\nhttps://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/testing" > build/alpine/etc/apk/repositories
	chroot build/alpine /bin/sh -c "apk update && apk add i2pd=$(I2PD) gnome=$(GNOME) librewolf=$(LIBREWOLF)"
	rm -rf build/alpine/etc/resolv.conf
	umount build/alpine/proc
	umount build/alpine/dev
	umount build/alpine/sys

# KERNEL

download_kernel:
	rm -rf "build/cloak/sources/linux-kernel"
	curl "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-$(KERNEL).tar.gz" -o "linux.tar.gz"
	tar -zxf "linux.tar.gz"
	rm "linux.tar.gz"
	mkdir -p build
	mv "linux-$(KERNEL)" "build/linux-kernel"

build_kernel:
	cp config/linux.config build/linux-kernel/.config
	cd build/linux-kernel && \
	make "-j$(JOBS)" && \
	INSTALL_PATH="$(shell pwd)/build/mnt/boot" make install
	rm -rf build/mnt/boot/*.old

# INITRAMFS

finish_initramfs:
	mkdir -p build/alpine/dev
	mknod -m 622 build/alpine/dev/console c 5 1 |:
	mknod -m 622 build/alpine/dev/tty0 c 4 0 |:
	cp init/init.sh build/alpine/etc/init

cp_initramfs:
	cp build/linux-kernel/usr/initramfs_data.cpio "build/mnt/boot/initramfs-$(KERNEL).img"

# ISO

create_img:
	mkdir -p build/mnt/boot/efi build/mnt/boot/grub
	cp config/grub.cfg build/mnt/boot/grub
	sed -i "s/VERSION/$(KERNEL)/g" build/mnt/boot/grub/grub.cfg

build_iso:
	grub-mkrescue -o Cloak.iso build/mnt

clean:
	umount build/alpine/proc |:
	umount build/alpine/dev |:
	umount build/alpine/sys |:
	rm -rf build
