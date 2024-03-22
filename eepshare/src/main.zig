const std = @import("std");
const libsam3 = @cImport(@cInclude("libsam3.h"));
const base32 = @import("base32.zig");

pub const allocator = std.heap.c_allocator;

pub fn main() !void {
    var ses: libsam3.Sam3Session = undefined;
    std.log.info("creating session...", .{});
    if (libsam3.sam3CreateSilentSession(@ptrCast(&ses), @ptrCast(libsam3.SAM3_HOST_DEFAULT), libsam3.SAM3_PORT_DEFAULT, @ptrCast(libsam3.SAM3_DESTINATION_TRANSIENT), libsam3.SAM3_SESSION_STREAM, 4, null) < 0) {
        @panic("FATAL: can't create session");
    }
    defer _ = libsam3.sam3CloseSession(@ptrCast(&ses));

    const b32 = try key_b32_to_main(ses.pubkey);
    std.log.info("listening on {s}.b32.i2p", .{b32});

    while (true) {
        const _conn: *libsam3.Sam3Connection = libsam3.sam3StreamAccept(@ptrCast(&ses)) orelse @panic("Failed to get a connector");

        _ = try std.Thread.spawn(.{}, struct {
            fn f(conn: *libsam3.Sam3Connection) void {
                var cmd: [256]u8 = undefined;

                if (libsam3.sam3tcpReceiveEx(conn.fd, &cmd, cmd.len, 1) < 0) {
                    std.log.err("Cant read from the user", .{});
                }

                std.debug.print("cmd: [{s}]\n", .{cmd});

                const respond = "HTTP/1.1 200 OK\r\n\r\n";
                if (libsam3.sam3tcpSend(conn.fd, respond, respond.len) < 0) {
                    std.log.err("Cant send to the user", .{});
                }

                _ = libsam3.sam3tcpDisconnect(conn.fd);
            }
        }.f, .{_conn});
    }
}

pub fn key_b32_to_main(_input: [617]u8) ![52]u8 {
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
    _ = base32.Encoding.init("abcdefghijklmnopqrstuvwxyz234567").encode(&buf, &hash);

    var buf_url: [52]u8 = undefined;
    @memcpy(&buf_url, buf[0..52]);

    return buf_url;
}
