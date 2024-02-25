# KabaOS
An I2P based OS for security

KabaOS is a live operating system based off of Alpine Linux that aims to help
users stay anonymous online. All network traffic that is sent out of your
computer is routed through the I2P network, keeping your data secure. KabaOS has
programs for your every need (like a browser, irc client, etc), with defaults
that make it run correctly over i2p.

## Building

You can download the repository with:

```
git clone https://github.com/arthurmelton/KabaOS
```

Once you have the source code you can run:

```
make download
```

to download all the pieces needed (only run one time) then run:

```
sudo make build
```

Or you can do the following to both download and build:

```
sudo make all
```

Once you have finished building you will have a file called `KabaOS.iso`, this
is your ISO.
