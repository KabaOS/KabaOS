#!/bin/sh

mount -o nosuid,nodev,noexec,hidepid=2 -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs dev /dev -o mode=0755,nosuid

mkdir /tmp
chmod 777 /tmp

/bin/ash -c "inotifywait -e delete_self '$(cat /var/root)' && poweroff" &

sysctl fs.protected_fifos=2
sysctl fs.protected_hardlinks=1
sysctl fs.protected_regular=2
sysctl fs.protected_symlinks=1
sysctl kernel.core_pattern=|/bin/false
sysctl kernel.deny_new_usb=1
sysctl kernel.kptr_restrict=2
sysctl kernel.perf_event_paranoid=3
sysctl kernel.sysrq=4
sysctl kernel.unprivileged_bpf_disabled=1
sysctl kernel.yama.ptrace_scope=2
sysctl net.core.bpf_jit_harden=2
sysctl net.ipv4.conf.all.accept_redirects=0
sysctl net.ipv4.conf.all.accept_source_route=0
sysctl net.ipv4.conf.all.rp_filter=1
sysctl net.ipv4.conf.all.secure_redirects=0
sysctl net.ipv4.conf.all.send_redirects=0
sysctl net.ipv4.conf.default.accept_redirects=0
sysctl net.ipv4.conf.default.accept_source_route=0
sysctl net.ipv4.conf.default.rp_filter=1
sysctl net.ipv4.conf.default.secure_redirects=0
sysctl net.ipv4.conf.default.send_redirects=0
sysctl net.ipv4.icmp_echo_ignore_all=1
sysctl net.ipv4.ip_unprivileged_port_start=0
sysctl net.ipv4.tcp_dsack=0
sysctl net.ipv4.tcp_fack=0
sysctl net.ipv4.tcp_rfc1337=1
sysctl net.ipv4.tcp_sack=0
sysctl net.ipv4.tcp_syncookies=1
sysctl net.ipv4.tcp_timestamps=0
sysctl net.ipv6.conf.all.accept_ra=0
sysctl net.ipv6.conf.all.accept_redirects=0
sysctl net.ipv6.conf.all.accept_source_route=0
sysctl net.ipv6.conf.all.use_tempaddr=2
sysctl net.ipv6.conf.default.accept_ra=0
sysctl net.ipv6.conf.default.accept_redirects=0
sysctl net.ipv6.conf.default.accept_source_route=0
sysctl net.ipv6.conf.default.use_tempaddr=2
sysctl vm.mmap_rnd_bits=32
sysctl vm.mmap_rnd_compat_bits=16

if [[ "x$(cat /proc/cmdline | cut -f4 -d ' ' | cut -c 7-)" == "x1" ]]; then
    # Enable strace on debugging
    echo 1 > /proc/sys/kernel/yama/ptrace_scope
fi

iptables-restore < /root/iptables.rules

/usr/sbin/kloak &

rfkill block all
rfkill unblock wifi

openrc
hostname OS

if [[ "x$(cat /proc/cmdline | cut -f4 -d ' ' | cut -c 7-)" == "x1" ]]; then
    echo
    echo "ENTER THE COMMAND \"exit\" TO CONTINUE WITH BOOTING"
    /bin/ash
fi

agetty -cJn -a Kaba tty1 linux
