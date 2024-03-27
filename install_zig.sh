#!/bin/sh

mkdir build
curl "$(curl "https://ziglang.org/download/index.json" | grep "linux-$(arch)" | head -n 1 | tr -d '"' | tr -d ',' | awk '{print $2}')" -o build/zig.tar.xz
cd build
tar -xf zig.tar.xz
rm zig.tar.xz
cd ..
mv build/zig-* build/zig
echo "When running make, add this to the end of your command ZIGCC=\"$(pwd)/build/zig/zig\""
