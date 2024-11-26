# KabaOS
A Security-Focused Live OS for I2P

KabaOS is a live operating system built on Alpine Linux, designed with
privacy and security at its core. All network traffic is routed through the
I2P (Invisible Internet Project) network, ensuring your online activities
remain anonymous and secure. KabaOS includes a selection of pre-configured
programs that are optimized for use over I2P, offering an easy-to-use,
privacy-first environment.

## Key Features

- **I2P-Enforced Network Routing**: All network traffic is routed through
	the I2P network by default, ensuring complete anonymity.
- **Encrypted Time Synchronization**: Time sync is secured and encrypted to
	prevent time-based tracking.
- **Encrypted DNS Queries**: Your DNS requests are encrypted to protect your
	browsing activity.
- **Mandatory I2P Routing**: Network traffic is forced through I2P via
	iptables for added security.
- **No Persistence**: The system does not retain any data between sessions,
	providing a clean slate on every boot.
- **Hardened Memory Allocator**: Increased security to mitigate memory-based
	vulnerabilities.
- **Minimal Firmware**: The system only includes Wi-Fi firmware, reducing
	potential attack vectors.
- **Secure Program Execution**: Programs are executed with predefined
	`bubblewrap` configurations for sandboxing and isolation.
- **Keystroke Anonymization**: Keystrokes are anonymized to prevent keylogging
	and tracking.
- **Custom Kernel Configuration**: The kernel is specifically configured to
	enhance anonymity and privacy.
- **USB-Triggered Auto Shutdown**: The system automatically shuts down if
	a USB device is removed, preventing data leakage.
- **Pre-configured for I2P**: Essential programs come pre-configured to work
	seamlessly over the I2P network.

## Included Programs

KabaOS comes with a suite of privacy-focused applications, including:

- **Monero GUI Wallet**: A secure cryptocurrency wallet that supports Monero.
- **Eepshare**: A custom tool for sharing files directly over the I2P network.
- **Age Encryption**: A simple and secure encryption tool for file encryption.
- **Deluge**: A lightweight, privacy-conscious BitTorrent client.
- **KeePassXC**: A secure password manager for storing sensitive credentials.
- **Kleopatra**: A graphical front-end for managing GPG keys and encryption.
- **Nheko**: A Matrix-based messaging client for encrypted communication.
- **Pidgin**: A multi-protocol messaging client supporting XMPP and IRC.
- **LibreWolf**: A privacy-focused web browser based on Firefox.
- **Metadata Cleaner**: A tool to remove metadata from files, ensuring your
    documents remain anonymous.

## Building KabaOS

To build KabaOS from source, you will need a system running Alpine Linux. Begin
by installing the required dependencies:

```sh
apk add bison curl flex g++ gcc gmp-dev grub grub-efi grub-bios linux-headers \
    make mpc1-dev mpfr-dev mtools musl-dev openssl-dev patch perl \
    squashfs-tools xorriso
```

### Cloning the Repository

Start by cloning the KabaOS repository:

```sh
git clone https://github.com/KabaOS/KabaOS
cd KabaOS
```

### Downloading Dependencies

Once you've cloned the repository, download the necessary external code with
the following command (this only needs to be done once):

```sh
make download
```

### Building KabaOS

Now, you can build the KabaOS image by running:

```sh
sudo make build
```

Alternatively, if you want to download the code and build it in one step, use:

```sh
sudo make all
```

After the build completes, you will find the `KabaOS.iso` file, which you
can burn to a USB drive or use in a virtual machine.
