export CC=gcc
export ZIGCC=zig
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

AGE=1.1.1-r9
AGETTY=2.39.3-r0
CHRONY=4.5-r0
CURL=8.5.0-r0
DBUS_X11=1.14.10-r0
DNSCRYPT_PROXY=2.1.5-r3
DNSCRYPT_PROXY_OPENRC=2.1.5-r3
DNSMASQ=2.90-r2
EUDEV=3.2.14-r0
GCOMPAT=1.1.0-r4
GDM=45.0.1-r0
GNOME_CONSOLE=45.0-r1
GNOME_TEXT_EDITOR=45.2-r0
GNUPG_SCDAEMON=2.4.4-r0
HARDENED_MALLOC=12-r1
I2PD=2.49.0-r1
INOTIFY_TOOLS=4.23.9.0-r0
IPTABLES=1.8.10-r3
LIBREWOLF=124.0.1_p1-r0
LIBSODIUM=1.0.19-r0
MAT2=0.13.4-r1
MESA_DRI_GALLIUM=23.3.6-r0
NAUTILUS=45.2.1-r0
NETWORKMANAGER=1.46.0-r0
NETWORKMANAGER_WIFI=1.46.0-r0
POLKIT_COMMON=124-r0
SHADOW_LOGIN=4.14.2-r0
UDEV_INIT_SCRIPTS=35-r1
UDEV_INIT_SCRIPTS_OPENRC=35-r1
WPA_SUPPLICANT=2.10-r10
XF86_INPUT_LIBINPUT=1.4.0-r0
XINIT=1.4.2-r1
XORG_SERVER=21.1.11-r0

KLOAK=9cbdf4484da19eb09653356e59ce42c37cecb523

DELUGE_GTK=2.1.1-r8
KEEPASSXC=2.7.7-r0
KLEOPATRA=23.08.4-r0
METADATA_CLEANER=2.5.4
PIDGIN=2.14.12-r3

.PHONY: build

all: download build

download: download_alpine download_kernel download_whence download_kloak download_metadata_cleaner

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
	echo -e "https://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/main\nhttps://dl-cdn.alpinelinux.org/alpine/v$(ALPINE_MINI)/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\nhttps://dl-cdn.alpinelinux.org/alpine/edge/testing" > build/alpine/etc/apk/repositories
	chroot build/alpine /bin/ash -c "apk update" || true
	chroot build/alpine /bin/ash -c "apk upgrade" || true
	chroot build/alpine /bin/ash -c "apk add \
		amd-ucode=$(AMD_UCODE) \
		intel-ucode=$(INTEL_UCODE)" || true
	chroot build/alpine /bin/ash -c "apk add \
		age=$(AGE) \
		agetty=$(AGETTY) \
		chrony=$(CHRONY) \
		curl=$(CURL) \
		dbus-x11=$(DBUS_X11) \
		dnscrypt-proxy-openrc=$(DNSCRYPT_PROXY_OPENRC) \
		dnscrypt-proxy=$(DNSCRYPT_PROXY) \
		dnsmasq=$(DNSMASQ) \
		eudev=$(EUDEV) \
		gcompat=$(GCOMPAT) \
		gdm=$(GDM) \
		gnome-console=$(GNOME_CONSOLE) \
		gnome-text-editor=$(GNOME_TEXT_EDITOR) \
		gnupg-scdaemon=$(GNUPG_SCDAEMON) \
		hardened-malloc=$(HARDENED_MALLOC) \
		i2pd=$(I2PD) \
		inotify-tools=$(INOTIFY_TOOLS) \
		iptables=$(IPTABLES) \
		keepassxc=$(KEEPASSXC) \
		kleopatra=$(KLEOPATRA) \
		librewolf=$(LIBREWOLF) \
		libsodium=$(LIBSODIUM) \
		mat2=$(MAT2) \
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
		deluge-gtk=$(DELUGE_GTK) \
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
	mkdir --parents build/initramfs/{bin,dev,etc,lib,lib64,mnt/iso,mnt/squashfs,mnt/tmpfs,proc,root,sbin,sys}
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
	cd build/initramfs && find . -print0 | cpio --null --create --verbose --format=newc | zstd -v -T$(JOBS) $(ZSTD_ARGS) --progress > ../mnt/boot/initramfs.cpio.zst

# WELCOME

build_welcome:
	cd welcome && $(ZIGCC) build -Doptimize=ReleaseFast # Hopefully musl and hardened malloc will save us if anything goes wrong
	patchelf --set-interpreter /lib/ld-musl-x86_64.so.1 welcome/zig-out/bin/welcome
	mv welcome/zig-out/bin/welcome build/alpine/bin/

# WELCOME

build_eepshare:
	cd eepshare && $(ZIGCC) build -Doptimize=ReleaseFast # Hopefully musl and hardened malloc will save us if anything goes wrong
	patchelf --set-interpreter /lib/ld-musl-x86_64.so.1 eepshare/zig-out/bin/eepshare
	mv eepshare/zig-out/bin/eepshare build/alpine/bin/

# KLOAK

download_kloak:
	curl -L "https://github.com/vmonaco/kloak/archive/$(KLOAK).tar.gz" -o kloak.tar.gz
	tar -xzf kloak.tar.gz
	mv kloak-$(KLOAK) build/kloak
	rm kloak.tar.gz

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
		build/alpine/usr/share/application/fr.romainvigier.MetadataCleaner.desktop \
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

CONFIG_TARGETS += config_chrony
config_chrony:
	mkdir -p build/alpine/var/run/chrony

CONFIG_TARGETS += config_dbus
config_dbus:
	mkdir -p build/alpine/run/dbus
	mkdir -p build/alpine/var/run/dbus
	chroot build/alpine /bin/ash -c "ln -sf /var/run/dbus/system_bus_socket /run/dbus/system_bus_socket"

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
