const allocator = @import("main.zig").allocator;
const base32 = @import("base32.zig");
const http = @import("http.zig");
const c = @import("main.zig").c;
const std = @import("std");
const gui = @import("gui.zig");

pub const share_type = enum { file, dir };

pub const options = struct {
    share_type: share_type,
    path: []u8,
};

pub const read_length = 2 * 1024;

pub fn serve(option: options, item: *c.GtkWidget, stop: *bool) !void {
    defer allocator.destroy(stop);

    var ses: c.Sam3Session = undefined;
    std.log.info("creating session for {s}", .{option.path});

    if (c.sam3CreateSilentSession(
        @ptrCast(&ses),
        @ptrCast(c.SAM3_HOST_DEFAULT),
        c.SAM3_PORT_DEFAULT,
        @ptrCast(c.SAM3_DESTINATION_TRANSIENT),
        c.SAM3_SESSION_STREAM,
        4,
        null,
    ) < 0) {
        @panic("FATAL: can't create session");
    }
    defer _ = c.sam3CloseSession(@ptrCast(&ses));
    defer std.log.info("Stopped listening for {s}", .{option.path});

    const key = try key_b32_to_serve(ses.pubkey);
    std.log.info("listening on {s}.b32.i2p for {s}", .{ key, option.path });

    const url = try allocator.alloc(u8, 61);
    defer allocator.free(url);

    std.mem.copyForwards(u8, url, &key);
    std.mem.copyForwards(u8, url[52..], ".b32.i2p");
    url[60] = 0;

    if (!stop.*) gui.loading_update(item, url);

    while (!stop.*) {
        const conn: *c.Sam3Connection = c.sam3StreamAccept(@ptrCast(&ses)) orelse @panic("Failed to get a connector");

        if (stop.*) {
            _ = c.sam3CloseConnection(conn);
            return;
        }

        _ = std.Thread.spawn(.{}, http.handle, .{ conn, option, key }) catch undefined;
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
