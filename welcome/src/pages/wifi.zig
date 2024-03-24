const allocator = @import("../main.zig").allocator;
const assert = std.debug.assert;
const c = @import("../main.zig").c;
const page_update = @import("../move.zig").page_update;
const std = @import("std");
const window = @import("../main.zig").global_window;

pub fn page(forward: bool) void {
    if (ip_address_has() catch @panic("Failed to read /proc/net/route")) {
        page_update(forward);
        return;
    }

    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@ptrCast(box), c.gtk_label_new("(wifi selector)"));
    c.gtk_window_set_child(@ptrCast(window.window.?), box);

    c.gtk_window_set_title(@ptrCast(window.window.?), "Select Wifi");
}

fn ip_address_has() !bool {
    const file = try std.fs.openFileAbsolute("/proc/net/route", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const line: [129]u8 = undefined;

    const read = (try reader.read(@constCast(&line)));

    assert(read == 129 or read == 128);
    return read == 129;
}
