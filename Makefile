export CC=gcc
export ARCH=$(shell arch)

export CFLAGS=-pipe -mtune=generic -O2 -Wall
export CXXFLAGS=$(CFLAGS)
export LDFLAGS=-pipe -mtune=generic
export JOBS=$(shell nproc)

# VERSIONS

ALPINE=3.19.1
ALPINE_MINI=3.19

KERNEL=6.6.12
LINUX_HARDENED=6.6.12-hardened1

LINUX_FIRMWARE=20240115-r0
WIRELESS_REGDB=2023.09.01-r0
ZSTD=1.5.5-r8

AMD_UCODE=20240115-r0
INTEL_UCODE=20231114-r0

AGETTY=2.39.3-r0
CURL=8.5.0-r0
DBUS_X11=1.14.10-r0
DNSCRYPT_PROXY=2.1.5-r2
DNSCRYPT_PROXY_OPENRC=2.1.5-r2
DNSMASQ=2.90-r2
EUDEV=3.2.14-r0
GDM=45.0.1-r0
GNOME_CONSOLE=45.0-r1
GNOME_TEXT_EDITOR=45.2-r0
HARDENED_MALLOC=12-r1
I2PD=2.49.0-r1
IPTABLES=1.8.10-r3
LIBREWOLF=123.0_p1-r0
MESA_DRI_GALLIUM=23.3.6-r0
NAUTILUS=45.2.1-r0
NETWORKMANAGER=1.44.2-r1
NETWORKMANAGER_WIFI=1.44.2-r1
POLKIT_COMMON=124-r0
SHADOW_LOGIN=4.14.2-r0
UDEV_INIT_SCRIPTS=35-r1
UDEV_INIT_SCRIPTS_OPENRC=35-r1
WPA_SUPPLICANT=2.10-r10
XF86_INPUT_LIBINPUT=1.4.0-r0
XINIT=1.4.2-r1
XORG_SERVER=21.1.11-r0

PIDGIN=2.14.12-r3

.PHONY: build

all: download build

download: download_alpine download_kernel download_whence

build: create_img build_kernel build_alpine build_initramfs config finish_alpine finish_initramfs build_iso

.SECONDEXPANSION:
config: $$(CONFIG_TARGETS)

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
	mkdir -p "build/alpine/dev"
	mkdir -p "build/alpine/sys"
	install -D -m 644 /etc/resolv.conf build/alpine/etc/resolv.conf
	echo -e "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/main\nhttps://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/testing" > build/alpine/etc/apk/repositories
	chroot build/alpine /bin/ash -c "apk update" || true
	chroot build/alpine /bin/ash -c "apk add \
		amd-ucode=$(AMD_UCODE) \
		intel-ucode=$(INTEL_UCODE)" || true
	chroot build/alpine /bin/ash -c "apk add \
		agetty=$(AGETTY) \
		curl=$(CURL) \
		dbus-x11=$(DBUS_X11) \
		dnscrypt-proxy-openrc=$(DNSCRYPT_PROXY_OPENRC) \
		dnscrypt-proxy=$(DNSCRYPT_PROXY) \
		dnsmasq=$(DNSMASQ) \
		eudev=$(EUDEV) \
		gdm=$(GDM) \
		gnome-console=$(GNOME_CONSOLE) \
		gnome-text-editor=$(GNOME_TEXT_EDITOR) \
		hardened-malloc=$(HARDENED_MALLOC) \
		i2pd=$(I2PD) \
		iptables=$(IPTABLES) \
		librewolf=$(LIBREWOLF) \
		mesa-dri-gallium=$(MESA_DRI_GALLIUM) \
		nautilus=$(NAUTILUS) \
		networkmanager-wifi=$(NETWORKMANAGER_WIFI) \
		networkmanager=$(NETWORKMANAGER) \
		polkit-common=$(POLKIT_COMMON) \
		shadow-login=$(SHADOW_LOGIN) \
		udev-init-scripts-openrc=$(UDEV_INIT_SCRIPTS_OPENRC) \
		udev-init-scripts=$(UDEV_INIT_SCRIPTS) \
		wpa_supplicant=$(WPA_SUPPLICANT) \
		xf86-input-libinput=$(XF86_INPUT_LIBINPUT) \
		xinit=$(XINIT) \
		xorg-server=$(XORG_SERVER)" || true
	chroot build/alpine /bin/ash -c "apk add \
		pidgin=$(PIDGIN)" || true
	chroot build/alpine /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools" || true
	chroot build/alpine /bin/ash -c "rc-update add udev" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-trigger" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-settle" || true
	chroot build/alpine /bin/ash -c "useradd -m Kaba" || true
	chroot build/alpine /bin/ash -c "mkdir -p /var/lib/misc" || true
	chroot build/alpine /bin/ash -c "touch /etc/fstab" || true
	chroot build/alpine /bin/ash -c "mkdir -p /run/openrc" || true
	chroot build/alpine /bin/ash -c "touch /run/openrc/softlevel" || true
	chroot build/alpine /bin/ash -c "rc-update add openrc-settingsd boot" || true
	chroot build/alpine /bin/ash -c "rc-update add networkmanager" || true
	chroot build/alpine /bin/ash -c "rc-update add elogind" || true
	chroot build/alpine /bin/ash -c "rc-update add dnsmasq" || true
	chroot build/alpine /bin/ash -c "rc-update add dnscrypt-proxy" || true
	mkdir -p "build/alpine/root"
	chroot build/alpine /bin/ash -c 'chown -R root:root "/root"' || true
	chroot build/alpine /bin/ash -c 'chmod 600 "/root"' || true
	chroot build/alpine /bin/ash -c 'chmod -R 600 "/root"' || true
	rm -rf build/alpine/etc/resolv.conf

finish_alpine:
	mkdir -p build/alpine/dev
	chroot build/alpine /bin/ash -c "rm -rf /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history" || true
	cd build/alpine && find . -print0 ! -path './bin/busybox' | cpio --null --create --verbose --format=newc | zstd -T$(JOBS) --ultra -22 --progress > ../mnt/alpine.cpio.zst

# WHEREACE
download_whence:
	curl "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/WHENCE?h=$$(echo "$(LINUX_FIRMWARE)" | cut -f1 -d'-')" -o build/WHENCE

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
	mkdir --parents build/initramfs/{bin,dev,etc,lib,lib64,mnt/iso,mnt/root,proc,root,sbin,sys}
	install -D -m 644 /etc/resolv.conf build/initramfs/etc/resolv.conf
	chroot build/initramfs /bin/ash -c "apk update" || true
	chroot build/initramfs /bin/ash -c "apk add \
		linux-firmware=$(LINUX_FIRMWARE) \
		wireless-regdb=$(WIRELESS_REGDB) \
		zstd=$(ZSTD)" || true
	chroot build/initramfs /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools" || true
	chroot build/initramfs /bin/ash -c "rm -rf /etc /lib/apk /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history" || true
	cp init/initramfs.sh build/initramfs/init
	chmod +x build/initramfs/init
	rm -rf build/initramfs/etc/resolv.conf

finish_initramfs:
	cd build/initramfs && find . -print0 | cpio --null --create --verbose --format=newc | zstd -v -T$(JOBS) --ultra -22 --progress > ../mnt/boot/initramfs.cpio.zst

# ISO

create_img:
	mkdir -p build/mnt/boot/efi build/mnt/boot/grub
	cp config/grub.cfg build/mnt/boot/grub
	sed -i "s/VERSION/$(KERNEL)/g" build/mnt/boot/grub/grub.cfg
	touch build/mnt/boot/grub/KabaOS.uuid

build_iso:
	grub-mkrescue --compress=xz -o KabaOS.iso build/mnt -- -volid KabaOS

# CONFIG

CONFIG_TARGETS += config_default
config_default:
	cp -r config/mnt/* build/alpine

CONFIG_TARGETS += config_dbus
config_dbus:
	mkdir -p build/alpine/run/dbus
	mkdir -p build/alpine/var/run/dbus
	chroot build/alpine /bin/ash -c "ln -sf /var/run/dbus/system_bus_socket /run/dbus/system_bus_socket"

CONFIG_TARGETS += config_firmware
config_firmware:
	cd build/initramfs/lib/firmware && cat ../../../WHENCE | grep -Po '(?<=File: ).*' | xargs -I{} zstd -v --exclude-compressed -T$(JOBS) --ultra -22 --progress --rm "{}" || true

CONFIG_TARGETS += config_i2pd
config_i2pd:
	mkdir -p build/alpine/var/lib/i2pd

CONFIG_TARGETS += config_init
config_init:
	cp init/init.sh build/alpine/etc/init

CONFIG_TARGETS += config_iptables
config_iptables:
	cp config/iptables.rules build/alpine/root/iptables.rules || true
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$I2PD_ID/$$(id -u i2pd)/" /root/iptables.rules'
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$DNSCRYPT_ID/$$(id -u dnscrypt)/" /root/iptables.rules'

CONFIG_TARGETS += config_ucode
config_ucode:
	mv build/alpine/boot/{amd,intel}-ucode.img build/mnt/boot || true
	zstd -v -f -T$(JOBS) --ultra -22 --progress --rm build/mnt/boot/{amd,intel}-ucode.img || true

CONFIG_TARGETS += config_user_init
config_user_init:
	cp init/post_init.sh build/alpine/home/Kaba/.profile

clean:
	rm -rf build
