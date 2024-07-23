# KabaOS
An I2P based OS made for security

KabaOS is a live operating system based off of Alpine Linux that aims to help
users stay anonymous online. All network traffic that is sent out of your
computer is routed through the I2P network, keeping your data secure. KabaOS has
programs for your every need (like a browser, IRC client, etc.), with defaults
that make it run correctly over I2P.

## Building

If you are on alpine, you can install all the necessary building programs by
running the following:

```sh
apk add bison curl desktop-file-utils elfutils-dev flex g++ gcc git glib-dev \
    gmp-dev grub grub-efi gtk4.0-dev itstool libadwaita-dev libevdev-dev \
    libsodium-dev linux-headers make meson mpc1-dev mpfr-dev mtools musl-dev \
    openssl-dev patch patchelf perl squashfs-tools xfconf-dev xorriso
```

You can download the repository with the following.

```
git https://github.com/arthurmelton/KabaOS
```

If your linux repository does not have some way of installing zig master, use
this (and read the output):

```sh
./install_zig.sh
```

Once you have the source code, you can run the following to download all of the
extra code that is needed. You only have to do this one time.

```
make download
```

Once you have downloaded all the code, you can actually build the project with
the following.

```
sudo make build
```

If you want to download all the code and then build it, you can run the
following.

```
sudo make all
```

Once you have finished building you will have a file called `KabaOS.iso`, this
is your ISO.
