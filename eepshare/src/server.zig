const allocator = @import("main.zig").allocator;
const base32 = @import("base32.zig");
const http = @import("http.zig");
const libsam3 = @cImport(@cInclude("libsam3.h"));
const std = @import("std");

pub const options = struct {
    share_type: enum { file, dir },
    path: []u8,
};

pub const read_length = 2 * 1024;

pub fn serve(option: options) !void {
    var ses: libsam3.Sam3Session = undefined;
    std.log.info("creating session for {s}", .{option.path});
    if (libsam3.sam3CreateSilentSession(@ptrCast(&ses), @ptrCast(libsam3.SAM3_HOST_DEFAULT), libsam3.SAM3_PORT_DEFAULT, @ptrCast(libsam3.SAM3_DESTINATION_TRANSIENT), libsam3.SAM3_SESSION_STREAM, 4, null) < 0) {
        @panic("FATAL: can't create session");
    }
    defer _ = libsam3.sam3CloseSession(@ptrCast(&ses));

    const key = try key_b32_to_serve(ses.pubkey);
    std.log.info("listening on {s}.b32.i2p for {s}", .{ key, option.path });

    while (true) {
        const _conn: *libsam3.Sam3Connection = libsam3.sam3StreamAccept(@ptrCast(&ses)) orelse @panic("Failed to get a connector");

        _ = try std.Thread.spawn(.{}, http.handle, .{ _conn, option, key });
    }
}

fn key_b32_to_serve(_input: [617]u8) ![52]u8 {
    var input = _input;
    var real_input: []u8 = &input;

    for (0..input.len) |i| {
        if (input[i] == '-') input[i] = '+';
        if (input[i] == '~') input[i] = '/';
        if (input[i] == '\x00') {
            real_input = input[0..i];
            break;
        }
    }

    const raw: []u8 = try allocator.alloc(u8, try std.base64.standard.Decoder.calcSizeForSlice(real_input));
    defer allocator.free(raw);

    try std.base64.standard.Decoder.decode(raw, real_input);

    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(raw, &hash, .{});

    var buf: [57]u8 = undefined;
    _ = base32.i2p_encoding.encode(&buf, &hash);

    var buf_url: [52]u8 = undefined;
    @memcpy(&buf_url, buf[0..52]);

    return buf_url;
}
