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
apk add bison curl flex g++ gcc gmp-dev grub grub-efi grub-bios linux-headers \
    make mpc1-dev mpfr-dev mtools musl-dev openssl-dev patch perl \
    squashfs-tools xorriso \
```

You can download the repository with the following.

```
git clone https://github.com/arthurmelton/KabaOS
cd KabaOS
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
following instead of doing download then build.

```
sudo make all
```

Once you have finished building you will have a file called `KabaOS.iso`, this
is your ISO.
