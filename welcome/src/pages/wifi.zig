const allocator = @import("../main.zig").allocator;
const c = @cImport(@cInclude("gtk/gtk.h"));
const std = @import("std");
const page_update = @import("../move.zig").page_update;
const window = @import("../main.zig").global_window;
const assert = std.debug.assert;

pub fn page(forward: bool) void {
    if (ip_address_has() catch @panic("Failed to read /proc/net/route")) {
        page_update(forward);
        return;
    }

    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@as(*c.GtkBox, @ptrCast(box)), c.gtk_label_new("(wifi selector)"));
    c.gtk_window_set_child(@as(*c.GtkWindow, @ptrCast(window.window.?)), box);

    c.gtk_window_set_title(@as(*c.GtkWindow, @ptrCast(window.window.?)), "Select Wifi");
}

fn ip_address_has() !bool {
    const file = try std.fs.openFileAbsolute("/proc/net/route", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const line: [129]u8 = undefined;

    const read = (try reader.read(@as([]u8, @constCast(&line))));

    assert(read == 129 or read == 128);
    return read == 129;
}
