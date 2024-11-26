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

program="$(basename "$0")"

GLOBAL="--new-session $(ro_bind "/usr/share/bwrap/$program")"

case "$program" in
    i2pd) c="$(share net) $(ro_bind /lib) $(ro_bind /usr/lib) $(ro_bind /usr/local/lib) $(bind /var/lib/i2pd) $(ro_bind /etc/i2pd) $(bind /var/log/i2pd/i2pd.log) $(ro_bind /etc/ssl/openssl.cnf) $(bind /run/i2pd/)";;
    *)
        echo "Program has not been configured yet" >> /dev/stdout
        exit 1
    ;;
esac

# strace if debug
if [[ "x$(cat /proc/cmdline | cut -f4 -d ' ' | cut -c 7-)" == "x1" ]]; then
    GLOBAL="$GLOBAL $(ro_bind "$(which strace)") $(bind /tmp/strace-$program.log)"
    c="$c -- strace -o /tmp/strace-$program.log"
    touch "/tmp/strace-$program.log"
    chmod 777 "/tmp/strace-$program.log"
fi

bwrap $GLOBAL $c -- /usr/share/bwrap/$program "$@"
