#!/bin/ash

if [ "$2" = "dhcp4-change" ] || [ "$2" = "dhcp6-change" ]; then
    rc-service -N i2pd start
fi
