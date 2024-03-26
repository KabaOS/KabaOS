#!/bin/ash

apk add git make curl patch gcc musl-dev flex bison g++ gmp-dev mpc1-dev mpfr-dev linux-headers elfutils-dev perl openssl-dev abuild
curl "$(curl "https://ziglang.org/download/index.json" | grep "linux-$(arch)" | head -n 1 | tr -d '"' | tr -d ',' | awk '{print $2}')" -o build/zig.tar.xz
cd build && tar -xf zig.tar.xz && rm zig.tar.xz
mv build/zig-* build/zig
echo "When running make, add the enviroment variable ZIGCC=\"$(pwd)/build/zig/zig\""
