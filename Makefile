export CC=../../build/initramfs/bin/musl-gcc
export CFLAGS=-march=x86-64 -O2 -Wall
export CXXFLAGS=-march=x86-64 -O2 -Wall
export JOBS=$(shell nproc)

# VERSIONS

KERNEL=6.6.12
MUSL=1.2.4
KERNEL_HEADERS=4.19.88-2
BOOST=1.84.0
ZLIB=1.3.1
OPENSSL=3.2.0

all: download build

download: download_kernel download_musl download_kernel_headers download_boost download_zlib download_openssl
build: create_img create_initramfs build_musl build_kernel_headers build_boost build_zlib build_openssl build_init build_kernel cp_initramfs build_iso

# KERNEL

download_kernel:
	rm -rf "sources/linux-kernel"
	curl "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-$(KERNEL).tar.gz" -o "linux.tar.gz"
	tar -zxf "linux.tar.gz"
	rm "linux.tar.gz"
	mkdir -p sources
	mv "linux-$(KERNEL)" "sources/linux-kernel"

build_kernel:
	cp config/linux.config sources/linux-kernel/.config
	cd sources/linux-kernel && \
	make "-j$(JOBS)" && \
	INSTALL_PATH=../../build/mnt/boot make install
	rm -rf build/mnt/boot/*.old

# MUSL

download_musl:
	rm -rf "sources/musl"
	curl "https://musl.libc.org/releases/musl-$(MUSL).tar.gz" -o "musl.tar.gz"
	tar -zxf "musl.tar.gz"
	rm "musl.tar.gz"
	mkdir -p sources
	mv "musl-$(MUSL)" "sources/musl"

build_musl:
	cd sources/musl && \
	mkdir -p ../../build/initramfs/usr/local/musl && \
	CC=gcc ./configure --prefix=../../build/initramfs --syslibdir=../../build/initramfs/lib x86_64 && \
	make "-j$(JOBS)" && \
	make install && \
	cp ../../build/initramfs/lib/musl-gcc.specs ../../build/musl-gcc-init.specs && \
	sed -i 's/\.\.\/\.\.\//..\//g' ../../build/musl-gcc-init.specs

# KERNEL_HEADERS

download_kernel_headers:
	rm -rf "sources/kernel-headers"
	curl -L "https://github.com/sabotage-linux/kernel-headers/archive/refs/tags/v$(KERNEL_HEADERS).tar.gz" -o "kernel-headers.tar.gz"
	tar -zxf "kernel-headers.tar.gz"
	rm "kernel-headers.tar.gz"
	mkdir -p sources
	mv "kernel-headers-$(KERNEL_HEADERS)" "sources/kernel-headers"

build_kernel_headers:
	cp -Lr sources/kernel-headers/x86_64/include/* build/initramfs/include

# BOOST

download_boost:
	rm -rf "sources/boost"
	curl -L "https://boostorg.jfrog.io/artifactory/main/release/$(BOOST)/source/boost_$(shell echo $(BOOST) | tr '.' '_').tar.gz" -o boost.tar.gz
	tar -zxf "boost.tar.gz"
	rm "boost.tar.gz"
	mkdir -p sources
	mv "boost_$(shell echo $(BOOST) | tr '.' '_')" "sources/boost"

build_boost:
	cd sources/boost && \
	./bootstrap.sh --prefix=../../build/initramfs --with-libraries=date_time,filesystem,program_options,system --with-toolset=gcc && \
	./b2 install -j $(JOBS)

# ZLIB

download_zlib:
	rm -rf "sources/zlib"
	curl "https://zlib.net/zlib-$(ZLIB).tar.gz" -o zlib.tar.gz
	tar -zxf "zlib.tar.gz"
	rm "zlib.tar.gz"
	mkdir -p sources
	mv "zlib-$(ZLIB)" "sources/zlib"

build_zlib:
	cd sources/zlib && \
	./configure --prefix=../../build/initramfs && \
	make "-j$(JOBS)" && \
	make install

# ZLIB

download_openssl:
	rm -rf "sources/openssl"
	curl -L "https://github.com/openssl/openssl/archive/refs/tags/openssl-$(OPENSSL).tar.gz" -o openssl.tar.gz
	tar -zxf "openssl.tar.gz"
	rm "openssl.tar.gz"
	mkdir -p sources
	mv "openssl-openssl-$(OPENSSL)" "sources/openssl"

build_openssl:
	cd sources/openssl && \
	./Configure --prefix=$(shell pwd)/build/initramfs no-docs && \
	make "-j$(JOBS)" && \
	make install

# INITRAMFS

create_initramfs:
	mkdir -p build/initramfs
	cp -r initramfs/* build/initramfs
	mknod -m 622 build/initramfs/dev/console c 5 1 |:
	mknod -m 622 build/initramfs/dev/tty0 c 4 0 |:

cp_initramfs:
	cp sources/linux-kernel/usr/initramfs_data.cpio "build/mnt/boot/initramfs-$(KERNEL).img"

# INIT

build_init: export CC = gcc

build_init:
	@$(MAKE) -C init -f init.mk
	cp init/init build/initramfs/etc

# ISO

create_img:
	mkdir -p build/mnt/boot/efi build/mnt/boot/grub
	cp config/grub.cfg build/mnt/boot/grub
	sed -i "s/VERSION/$(KERNEL)/g" build/mnt/boot/grub/grub.cfg

build_iso:
	grub-mkrescue -o Cloak.iso build/mnt

clean:
	for i in sources/*; do \
		make -C $$i clean; \
	done
	rm -rf build
