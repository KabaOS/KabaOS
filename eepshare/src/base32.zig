// Modified from https://github.com/gernest/base32 Licensed under MIT by Geofrey Ernest

const std = @import("std");

const encode_i2p = "abcdefghijklmnopqrstuvwxyz234567";

pub const i2p_encoding = Encoding.initWithPadding(encode_i2p, i2p_padding_char);
const i2p_padding_char = '=';

pub const Encoding = struct {
    buf: [32]u8,
    decode_map: [256]u8,
    pad_char: ?u8 = null,

    pub fn initWithPadding(encoder_string: []const u8, pad_char: ?u8) Encoding {
        std.debug.assert(encoder_string.len == 32);
        if (pad_char) |c| {
            std.debug.assert(!(c == 'r' or c == '\n' or c > 0xff));
        }
        return Encoding{
            .buf = blk: {
                var a: [32]u8 = undefined;
                std.mem.copyForwards(u8, a[0..], encoder_string);
                break :blk a;
            },
            .decode_map = blk: {
                var a = [_]u8{0xFF} ** 256;
                for (encoder_string, 0..) |c, i| {
                    a[@intCast(c)] = @intCast(i);
                }
                break :blk a;
            },
            .pad_char = pad_char,
        };
    }

    pub fn encode(
        self: Encoding,
        destination: []u8,
        source: []const u8,
    ) []const u8 {
        var dst = destination;
        var src = source;
        var n: usize = 0;
        while (src.len > 0) {
            var b = [_]u8{0} ** 8;
            switch (src.len) {
                1 => {
                    case1(b[0..], src);
                },
                2 => {
                    case2(b[0..], src);
                    case1(b[0..], src);
                },
                3 => {
                    case3(b[0..], src);
                    case2(b[0..], src);
                    case1(b[0..], src);
                },
                4 => {
                    case4(b[0..], src);
                    case3(b[0..], src);
                    case2(b[0..], src);
                    case1(b[0..], src);
                },
                else => {
                    b[7] = src[4] & 0x1F;
                    b[6] = src[4] >> 5;
                    case4(b[0..], src);
                    case3(b[0..], src);
                    case2(b[0..], src);
                    case1(b[0..], src);
                },
            }
            const size = dst.len;
            if (size >= 8) {
                dst[0] = self.buf[b[0] & 31];
                dst[1] = self.buf[b[1] & 31];
                dst[2] = self.buf[b[2] & 31];
                dst[3] = self.buf[b[3] & 31];
                dst[4] = self.buf[b[4] & 31];
                dst[5] = self.buf[b[5] & 31];
                dst[6] = self.buf[b[6] & 31];
                dst[7] = self.buf[b[7] & 31];
                n += 8;
            } else {
                var i: usize = 0;
                while (i < size) : (i += 1) {
                    dst[i] = self.buf[b[i] & 31];
                }
                n += i;
            }
            if (src.len < 5) {
                if (self.pad_char == null) break;
                dst[7] = self.pad_char.?;
                if (src.len < 4) {
                    dst[6] = self.pad_char.?;
                    dst[5] = self.pad_char.?;
                    if (src.len < 3) {
                        dst[4] = self.pad_char.?;
                        if (src.len < 2) {
                            dst[3] = self.pad_char.?;
                            dst[2] = self.pad_char.?;
                        }
                    }
                }
                break;
            }
            src = src[5..];
            dst = dst[8..];
        }
        return destination[0..n];
    }
};

inline fn dec2(dst: []u8, dsti: usize, dbuf: []u8) void {
    dst[dsti + 0] = dbuf[0] << 3 | dbuf[1] >> 2;
}

inline fn dec4(dst: []u8, dsti: usize, dbuf: []u8) void {
    dst[dsti + 1] = dbuf[1] << 6 | dbuf[2] << 1 | dbuf[3] >> 4;
}

inline fn dec5(dst: []u8, dsti: usize, dbuf: []u8) void {
    dst[dsti + 2] = dbuf[3] << 4 | dbuf[4] >> 1;
}

inline fn dec7(dst: []u8, dsti: usize, dbuf: []u8) void {
    dst[dsti + 3] = dbuf[4] << 7 | dbuf[5] << 2 | dbuf[6] >> 3;
}

inline fn dec8(dst: []u8, dsti: usize, dbuf: []u8) void {
    dst[dsti + 4] = dbuf[6] << 5 | dbuf[7];
}

inline fn case1(b: []u8, src: []const u8) void {
    b[1] |= (src[0] << 2) & 0x1F;
    b[0] = src[0] >> 3;
}

inline fn case2(b: []u8, src: []const u8) void {
    b[3] |= (src[1] << 4) & 0x1F;
    b[2] = (src[1] >> 1) & 0x1F;
    b[1] = (src[1] >> 6) & 0x1F;
}

inline fn case3(b: []u8, src: []const u8) void {
    b[4] |= (src[2] << 1) & 0x1F;
    b[3] = (src[2] >> 4) & 0x1F;
}

inline fn case4(b: []u8, src: []const u8) void {
    b[6] |= (src[3] << 3) & 0x1F;
    b[5] = (src[3] >> 2) & 0x1F;
    b[4] = src[3] >> 7;
}
