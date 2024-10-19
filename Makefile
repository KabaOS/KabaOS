export CC=gcc
export ZIGCC=zig
export ARCH=$(shell arch)

export CFLAGS=-pipe -mtune=generic -O2 -Wall
export CXXFLAGS=$(CFLAGS)
export LDFLAGS=-pipe -mtune=generic
export JOBS=$(shell nproc)

# VERSIONS

ALPINE=3.20.3
ALPINE_MINI=3.20

KERNEL=6.6.54
LINUX_HARDENED=v6.6.54-hardened1

.PHONY: build

all: download build

download: download_alpine download_kernel download_whence

build: create_img build_kernel build_alpine build_initramfs config finish_alpine finish_initramfs build_iso

.SECONDEXPANSION:
config: $$(CONFIG_TARGETS)

# ARGS

ZSTD_ARGS=$(shell if [ "$(FAST)" != "y" ]; then echo "--ultra -22"; fi)

# ALPINE

download_alpine:
	mkdir -p build/alpine
	curl "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/releases/$(ARCH)/alpine-minirootfs-$(ALPINE)-$(ARCH).tar.gz" -o build/alpine/alpine.tar.gz
	cd build/alpine/ && tar -xzf alpine.tar.gz
	rm build/alpine/alpine.tar.gz
	cp -r build/alpine build/initramfs

build_alpine:
	mkdir -p build/alpine/
	mkdir -p build/alpine/proc
	mkdir -p build/alpine/dev
	mkdir -p build/alpine/sys
	mount --types proc /proc build/alpine/proc
	install -D -m 644 /etc/resolv.conf build/alpine/etc/resolv.conf
	echo -e "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/main\nhttps://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/community" > build/alpine/etc/apk/repositories || true
	chroot build/alpine /bin/ash -c "apk update" || true
	chroot build/alpine /bin/ash -c "apk upgrade" || true
	chroot build/alpine /bin/ash -c "apk add alpine-sdk" || true
	cp -r pkgs/main/ build/alpine/aports
	chroot build/alpine /bin/ash -c "echo '' | abuild-keygen -a" || true
	chroot build/alpine /bin/ash -c "apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
		mat2" || true
	chroot build/alpine /bin/ash -c "cd /aports; \
		for i in *; do \
			cd \"\$$i\" && abuild -F -r; cd ..; \
			apk add --allow-untrusted ~/packages/aports/*/\"\$$i\"-*.apk; \
		done" || true
	chroot build/alpine /bin/ash -c "apk del aa-zig-9999" || true
	rm -rf build/alpine/aports
	rm -rf build/alpine/root/packages
	chroot build/alpine /bin/ash -c "apk add \
		amd-ucode \
		intel-ucode" || true
	chroot build/alpine /bin/ash -c "apk add \
		agetty \
		chrony \
		curl \
		dbus-x11 \
		dnscrypt-proxy \
		dnscrypt-proxy-openrc \
		dnsmasq \
		elogind \
		eudev \
		gnupg-scdaemon \
		i2pd \
		inotify-tools \
		iptables \
		mesa-dri-gallium \
		nautilus \
		network-manager-applet \
		networkmanager \
		networkmanager-wifi \
		openrc \
		polkit-common \
		shadow \
		shadow-login \
		udev-init-scripts \
		udev-init-scripts-openrc \
		wpa_supplicant \
		xf86-input-libinput \
		xfce4 \
		xfce4-terminal \
		xinit \
		xorg-server" || true
	chroot build/alpine /bin/ash -c "apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
		hardened-malloc" || true
	chroot build/alpine /bin/ash -c "apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
		librewolf" || true
	chroot build/alpine /bin/ash -c "apk add \
		age \
		deluge-gtk \
		keepassxc \
		kleopatra \
		nheko \
		pidgin" || true
	chroot build/alpine /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools alpine-sdk" || true
	chroot build/alpine /bin/ash -c "rc-update add udev" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-trigger" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-settle" || true
	chroot build/alpine /bin/ash -c "useradd -m Kaba" || true
	chroot build/alpine /bin/ash -c "mkdir -p /var/lib/misc" || true
	chroot build/alpine /bin/ash -c "touch /etc/fstab" || true
	chroot build/alpine /bin/ash -c "mkdir -p /run/openrc" || true
	chroot build/alpine /bin/ash -c "touch /run/openrc/softlevel" || true
	chroot build/alpine /bin/ash -c "rc-update add local" || true
	chroot build/alpine /bin/ash -c "rc-update add elogind" || true
	chroot build/alpine /bin/ash -c "rc-update add networkmanager" || true
	chroot build/alpine /bin/ash -c "rc-update add dnsmasq" || true
	chroot build/alpine /bin/ash -c "rc-update add dnscrypt-proxy" || true
	chroot build/alpine /bin/ash -c "rc-update add chronyd" || true
	mkdir -p "build/alpine/root"
	chroot build/alpine /bin/ash -c 'chown -R root:root "/root"' || true
	chroot build/alpine /bin/ash -c 'chmod 600 "/root"' || true
	chroot build/alpine /bin/ash -c 'chmod -R 600 "/root"' || true
	rm -rf build/alpine/etc/resolv.conf
	umount build/alpine/proc

finish_alpine:
	mkdir -p build/alpine/dev
	chroot build/alpine /bin/ash -c "rm -rf /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history /root/.abuild" || true
	mksquashfs build/alpine build/mnt/alpine.zst.squashfs -noappend -comp zstd $(shell if [ "$(FAST)" != "y" ]; then echo "-Xcompression-level 22"; fi)

# WHEREACE

download_whence:
	curl "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/WHENCE" -o build/WHENCE

# KERNEL

download_kernel:
	rm -rf "build/linux-kernel"
	curl "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-$(KERNEL).tar.gz" -o "linux.tar.gz"
	tar -zxf "linux.tar.gz"
	rm "linux.tar.gz"
	mkdir -p build
	mv "linux-$(KERNEL)" "build/linux-kernel"
	curl "https://github.com/anthraxx/linux-hardened/releases/download/$(LINUX_HARDENED)/linux-hardened-$(LINUX_HARDENED).patch" -o build/linux-kernel/linux-hardened.patch
	cd build/linux-kernel && patch -Np1 < linux-hardened.patch

build_kernel:
	cp config/linux.config build/linux-kernel/.config
	cd build/linux-kernel && \
	make "-j$(JOBS)" && \
	INSTALL_PATH="$(shell pwd)/build/mnt/boot" make install
	rm -rf build/mnt/boot/*.old

# INITRAMFS

build_initramfs:
	mkdir --parents build/initramfs/bin build/initramfs/dev \
		build/initramfs/etc build/initramfs/lib build/initramfs/lib64 \
		build/initramfs/mnt/iso build/initramfs/mnt/squashfs \
		build/initramfs/mnt/tmpfs build/initramfs/proc build/initramfs/root \
		build/initramfs/sbin build/initramfs/sys
	install -D -m 644 /etc/resolv.conf build/initramfs/etc/resolv.conf
	chroot build/initramfs /bin/ash -c "apk update" || true
	# linux-firmware-other for iwlwifi
	chroot build/initramfs /bin/ash -c "apk add \
		linux-firmware-other \
		wireless-regdb \
		zstd" || true
	chroot build/initramfs /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools" || true
	chroot build/initramfs /bin/ash -c "rm -rf /etc /lib/apk /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history" || true
	cp init/initramfs.sh build/initramfs/init
	chmod +x build/initramfs/init
	rm -rf build/initramfs/etc/resolv.conf

finish_initramfs:
	cd build/initramfs && find . -print0 | cpio --null --create --verbose --format=newc | zstd -v -T$(JOBS) $(ZSTD_ARGS) --progress > ../mnt/boot/initramfs.cpio.zst

# ISO

create_img:
	mkdir -p build/mnt/boot/efi build/mnt/boot/grub
	cp config/grub.cfg build/mnt/boot/grub
	sed -i "s/VERSION/$(KERNEL)/g" build/mnt/boot/grub/grub.cfg
	touch build/mnt/boot/grub/KabaOS.uuid

build_iso:
	sed -i 's/$$HASH/$(shell sha256sum build/mnt/alpine.zst.squashfs | cut -c-64)/g' build/mnt/boot/grub/grub.cfg
	grub-mkrescue --compress=xz -o KabaOS.iso build/mnt -- -volid KabaOS

# CONFIG

CONFIG_TARGETS += config_apk
config_apk:
	rm -rf build/alpine/etc/apk

CONFIG_TARGETS += config_default
config_default:
	cp -r config/mnt/* build/alpine

CONFIG_TARGETS += config_dbus
config_dbus:
	mkdir -p build/alpine/run/dbus
	mkdir -p build/alpine/var/run/dbus
	chroot build/alpine /bin/ash -c "ln -s /var/run/dbus/system_bus_socket /run/dbus/system_bus_socket" || true

CONFIG_TARGETS += config_chrony
config_chrony:
	mkdir -p build/alpine/var/run/chrony

CONFIG_TARGETS += config_firmware
config_firmware:
	mkdir build/initramfs/lib/firmware2
	cp -r build/initramfs/lib/firmware/iwlwifi-* build/initramfs/lib/firmware2
	cp -r build/initramfs/lib/firmware/regulatory.db* build/initramfs/lib/firmware2
	rm -r build/initramfs/lib/firmware
	mv build/initramfs/lib/firmware2 build/initramfs/lib/firmware
	cd build/initramfs/lib/firmware && cat ../../../WHENCE | grep '^File: ' | cut -c7- | xargs -I{} zstd -v --exclude-compressed -T$(JOBS) $(ZSTD_ARGS) --progress --rm "{}" || true

CONFIG_TARGETS += config_i2pd
config_i2pd:
	mkdir -p build/alpine/var/lib/i2pd
	chroot build/alpine /bin/ash -c 'chown -R i2pd /var/lib/i2pd'

CONFIG_TARGETS += config_init
config_init:
	cp init/init.sh build/alpine/etc/init

CONFIG_TARGETS += config_iptables
config_iptables:
	cp config/iptables.rules build/alpine/root/iptables.rules || true
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$I2PD_ID/$$(id -u i2pd)/" /root/iptables.rules'
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$DNSCRYPT_ID/$$(id -u dnscrypt)/" /root/iptables.rules'
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$CHRONY_ID/$$(id -u chrony)/" /root/iptables.rules'

CONFIG_TARGETS += config_librewolf
config_librewolf:
	mkdir -p build/alpine/home/Kaba/.local/share/xfce4/helpers
	# From https://cgit.freedesktop.org/xdg/xdg-utils/tree/scripts/xdg-settings.in#n526
	export INPUT="build/alpine/usr/share/applications/librewolf.desktop" && \
	export OUTPUT="build/alpine/home/Kaba/.local/share/xfce4/helpers/librewolf.desktop" && \
	sed -e 's/^Type=.*/Type=X-XFCE-Helper/' -e '/^Exec[=[]/,$$d' "$$INPUT" > "$$OUTPUT" && \
	echo "X-XFCE-Category=WebBrowser" >> "$$OUTPUT" && \
	echo "X-XFCE-Commands=librewolf" >> "$$OUTPUT" && \
	echo "X-XFCE-CommandsWithParameter=librewolf \"%s\"" >> "$$OUTPUT" && \
	sed -n -e 's/^Type=.*/Type=X-XFCE-Helper/' -e '/^Exec[=[]/,$$p' "$$INPUT" >> "$$OUTPUT"

CONFIG_TARGETS += config_osinfo
config_osinfo:
	rm -rf build/alpine/usr/share/osinfo/

CONFIG_TARGETS += config_ucode
config_ucode:
	mv build/alpine/boot/amd-ucode.img build/mnt/boot || true
	mv build/alpine/boot/intel-ucode.img build/mnt/boot || true

CONFIG_TARGETS += config_user_init
config_user_init:
	cp init/post_init.sh build/alpine/home/Kaba/.profile

CONFIG_TARGETS += config_home
config_home:
	chroot build/alpine /bin/ash -c 'chown -R $$(id -u Kaba):$$(id -g Kaba) /home/Kaba'

clean:
	rm -rf build
