#!/bin/sh

ro_bind () {
    echo "--ro-bind $1 $1"
}


bind () {
    echo "--bind $1 $1"
}

share () {
    echo "$(printf "user\nipc\npid\nnet\nuts\ncgroup\n$(printf "%s\n" "$@")" | sort | uniq -u | awk '{print "--unshare-"$1}')"
}

lib_exe () {
    echo "$(ldd "$1" | grep \.so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq | awk '{print "--ro-bind "$1" "$1}')"
}

program="$(basename "$0")"

GLOBAL="--new-session $(ro_bind "/usr/share/bwrap/$program") $(lib_exe "/usr/share/bwrap/$program")"

case "$program" in
    i2pd) c="$(share net) $(bind /var/lib/i2pd) $(ro_bind /etc/i2pd) $(bind /var/log/i2pd/i2pd.log) $(ro_bind /etc/ssl/openssl.cnf) $(bind /run/i2pd/)";;
    dnscrypt-proxy) c="$(share net) $(bind /etc/dnscrypt-proxy) $(bind /run/dnscrypt-proxy) $(bind /var/log/dnscrypt-proxy) $(bind /var/cache/dnscrypt-proxy) --cap-add cap_net_bind_service";;
    *)
        echo "Program has not been configured yet" >> /dev/stdout
        exit 1
    ;;
esac

# strace if debug
if [[ "x$(cat /proc/cmdline | cut -f4 -d ' ' | cut -c 7-)" == "x1" ]]; then
    GLOBAL="$GLOBAL $(ro_bind "$(which strace)") $(lib_exe "$(which strace)")"
    c="$c -- strace"
    exec &> "/tmp/strace-$program.log"
    set -o xtrace
fi

bwrap $GLOBAL $c -- /usr/share/bwrap/$program "$@"
