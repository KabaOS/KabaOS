export CC=gcc
export ZIGCC=zig
export ARCH=$(shell arch)

export CFLAGS=-pipe -mtune=generic -O2 -Wall
export CXXFLAGS=$(CFLAGS)
export LDFLAGS=-pipe -mtune=generic
export JOBS=$(shell nproc)

# VERSIONS

ALPINE=3.20.0
ALPINE_MINI=3.20

KERNEL=6.9.3
LINUX_HARDENED=v6.9.3-hardened1

EEPSHARE=731d8cb62393bbfc94c813479e445824f51bf51f
KLOAK=9cbdf4484da19eb09653356e59ce42c37cecb523
METADATA_CLEANER=2.5.5
WELCOME=347f38de225056fe95348fb4091a24bddfb6212b

.PHONY: build

all: download build

download: download_alpine download_kernel download_whence download_welcome download_eepshare download_kloak download_metadata_cleaner

build: create_img build_kernel build_alpine build_initramfs build_welcome build_eepshare build_kloak build_metadata_cleaner config finish_alpine finish_initramfs build_iso

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
	mkdir -p "build/alpine/dev"
	mkdir -p "build/alpine/sys"
	install -D -m 644 /etc/resolv.conf build/alpine/etc/resolv.conf
	echo -e "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/main\nhttps://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/testing" > build/alpine/etc/apk/repositories
	chroot build/alpine /bin/ash -c "apk update" || true
	chroot build/alpine /bin/ash -c "apk upgrade" || true
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
		gcompat \
		gnupg-scdaemon \
		hardened-malloc \
		i2pd \
		inotify-tools \
		iptables \
		librewolf \
		libsodium \
		mesa-dri-gallium \
		nautilus \
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
	chroot build/alpine /bin/ash -c "apk add \
		age \
		deluge-gtk \
		keepassxc \
		kleopatra \
		mat2 \
		nheko \
		pidgin" || true
	chroot build/alpine /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools" || true
	chroot build/alpine /bin/ash -c "rc-update add udev" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-trigger" || true
	chroot build/alpine /bin/ash -c "rc-update add udev-settle" || true
	chroot build/alpine /bin/ash -c "useradd -m Kaba" || true
	chroot build/alpine /bin/ash -c "mkdir -p /var/lib/misc" || true
	chroot build/alpine /bin/ash -c "touch /etc/fstab" || true
	chroot build/alpine /bin/ash -c "mkdir -p /run/openrc" || true
	chroot build/alpine /bin/ash -c "touch /run/openrc/softlevel" || true
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

finish_alpine:
	mkdir -p build/alpine/dev
	chroot build/alpine /bin/ash -c "rm -rf /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history" || true
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
	mkdir --parents build/initramfs/{bin,dev,etc,lib,lib64,mnt/iso,mnt/squashfs,mnt/tmpfs,proc,root,sbin,sys}
	install -D -m 644 /etc/resolv.conf build/initramfs/etc/resolv.conf
	chroot build/initramfs /bin/ash -c "apk update" || true
	chroot build/initramfs /bin/ash -c "apk add \
		linux-firmware \
		wireless-regdb \
		zstd" || true
	chroot build/initramfs /bin/ash -c "apk del alpine-baselayout alpine-keys apk-tools" || true
	chroot build/initramfs /bin/ash -c "rm -rf /etc /lib/apk /var/cache/* /root/.cache /root/.ICEauthority /root/.ash_history" || true
	cp init/initramfs.sh build/initramfs/init
	chmod +x build/initramfs/init
	rm -rf build/initramfs/etc/resolv.conf

finish_initramfs:
	cd build/initramfs && find . -print0 | cpio --null --create --verbose --format=newc | zstd -v -T$(JOBS) $(ZSTD_ARGS) --progress > ../mnt/boot/initramfs.cpio.zst

# WELCOME

download_welcome:
	cd build && git clone https://github.com/KabaOS/welcome && cd welcome && git reset --hard "$(WELCOME)" && git submodule update --init --recursive

build_welcome:
	cd build/welcome && $(ZIGCC) build -Doptimize=ReleaseSmall # Hopefully musl and hardened malloc will save us if anything goes wrong
	patchelf --set-interpreter /lib/ld-musl-x86_64.so.1 build/welcome/zig-out/bin/welcome
	mv build/welcome/zig-out/bin/welcome build/alpine/bin/

# EEPSHARE

download_eepshare:
	cd build && git clone https://github.com/KabaOS/eepshare && cd eepshare && git reset --hard "$(EEPSHARE)" && git submodule update --init --recursive

build_eepshare:
	cd build/eepshare && $(ZIGCC) build -Doptimize=ReleaseSmall # Hopefully musl and hardened malloc will save us if anything goes wrong
	patchelf --set-interpreter /lib/ld-musl-x86_64.so.1 build/eepshare/zig-out/bin/eepshare
	mv build/eepshare/zig-out/bin/eepshare build/alpine/bin/

# KLOAK

download_kloak:
	cd build && git clone https://github.com/vmonaco/kloak && cd kloak && git reset --hard "$(KLOAK)" && git submodule update --init --recursive

build_kloak:
	cd build/kloak && CFLAGS="-Wl,-rpath=../build/alpine/lib -Wl,--dynamic-linker=/lib/ld-musl-x86_64.so.1" make kloak
	mv build/kloak/kloak build/alpine/sbin

# METADATA CLEANER

download_metadata_cleaner:
	curl -L "https://gitlab.com/rmnvgr/metadata-cleaner/-/archive/v$(METADATA_CLEANER)/metadata-cleaner-v$(METADATA_CLEANER).tar.gz" -o metadata-cleaner.tar.gz
	tar -xzf metadata-cleaner.tar.gz
	mv metadata-cleaner-v$(METADATA_CLEANER) build/metadata-cleaner
	rm metadata-cleaner.tar.gz

build_metadata_cleaner:
	cd build/metadata-cleaner && meson builddir
	cd build/metadata-cleaner && meson configure -Dprefix=$(shell pwd)/build/alpine -Ddatadir=usr/share builddir
	cd build/metadata-cleaner && meson install -C builddir
	chroot build/alpine /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/
	for i in build/alpine/usr/share/dbus-1/services/fr.romainvigier.MetadataCleaner.service \
		build/alpine/usr/share/applications/fr.romainvigier.MetadataCleaner.desktop \
		build/alpine/bin/metadata-cleaner; do \
		sed -i -e 's/$(shell pwd | sed 's/\//\\\//g')\/build\/alpine//g' "$$i"; \
	done

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

CONFIG_TARGETS += config_default
config_default:
	cp -r config/mnt/* build/alpine

CONFIG_TARGETS += config_dbus
config_dbus:
	mkdir -p build/alpine/run/dbus
	mkdir -p build/alpine/var/run/dbus
	chroot build/alpine /bin/ash -c "ln -sf /var/run/dbus/system_bus_socket /run/dbus/system_bus_socket"

CONFIG_TARGETS += config_chrony
config_chrony:
	mkdir -p build/alpine/var/run/chrony

CONFIG_TARGETS += config_firmware
config_firmware:
	cd build/initramfs/lib/firmware && cat ../../../WHENCE | grep -Po '(?<=File: ).*' | xargs -I{} zstd -v --exclude-compressed -T$(JOBS) $(ZSTD_ARGS) --progress --rm "{}" || true

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
	chroot build/alpine /bin/ash -c 'sed -i "s/\$$CHRONY_ID/$$(id -u chrony)/" /root/iptables.rules'

CONFIG_TARGETS += config_ucode
config_ucode:
	mv build/alpine/boot/{amd,intel}-ucode.img build/mnt/boot || true
	zstd -v -f -T$(JOBS) $(ZSTD_ARGS) --progress --rm build/mnt/boot/{amd,intel}-ucode.img || true

CONFIG_TARGETS += config_user_init
config_user_init:
	cp init/post_init.sh build/alpine/home/Kaba/.profile

CONFIG_TARGETS += config_home
config_home:
	chroot build/alpine /bin/ash -c 'chown -R $$(id -u Kaba):$$(id -g Kaba) /home/Kaba'

clean:
	rm -rf build
