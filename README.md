# KabaOS
An I2P based OS for security

KabaOS is a live operating system based off of Alpine Linux that aims to help
users stay anonymous online. All network traffic that is sent out of your
computer is routed through the I2P network, keeping your data secure. KabaOS has
programs for your every need (like a browser, irc client, etc), with defaults
that make it run correctly over i2p.

## Building

You can download the repository with the following.

```
git clone --recursive https://github.com/arthurmelton/KabaOS
```

If you are on alpine you can install all of the nessisary building programs by
running the following (it will tell you to set an enviroment variable when
running make, dont forget to do so):

```sh
./alpine_setup.sh

```

Once you have the source code you can run the following to download all of the
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
