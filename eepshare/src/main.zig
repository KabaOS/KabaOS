const server = @import("server.zig");
const std = @import("std");

pub const allocator = std.heap.c_allocator;
pub const libsam3 = @cImport(@cInclude("libsam3.h"));

pub fn main() !void {
    _ = try std.Thread.spawn(.{}, server.serve, .{.{ .share_type = .dir, .path = @constCast("/var") }});
    std.time.sleep(1000000000);
    _ = try std.Thread.spawn(.{}, server.serve, .{.{ .share_type = .file, .path = @constCast("/usr/bin/env") }});
    std.time.sleep(1000000000);
    try server.serve(.{ .share_type = .dir, .path = @constCast("/tmp/") });
}
