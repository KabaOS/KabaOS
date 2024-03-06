const allocator = @import("../main.zig").allocator;
const c = @cImport(@cInclude("gtk/gtk.h"));
const std = @import("std");
const update = @import("../move.zig").update;
const window = @import("../main.zig").global_window;

pub fn wifi(forward: bool) void {
    if (ipAddressCount() catch @panic("Failed to read /proc/net/route") > 0) {
        update(forward);
        return;
    }

    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@as(*c.GtkBox, @ptrCast(box)), c.gtk_label_new("(wifi selector)"));
    c.gtk_window_set_child(@as(*c.GtkWindow, @ptrCast(window.window.?)), box);

    c.gtk_window_set_title(@as(*c.GtkWindow, @ptrCast(window.window.?)), "Select Wifi");
}

fn ipAddressCount() !usize {
    const file = try std.fs.openFileAbsolute("/proc/net/route", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const line = try allocator.alloc(u8, 128);
    defer allocator.free(line);

    var count: usize = 0;

    while ((try reader.read(line)) > 0) {
        count += 1;
    }

    return count - 1;
}
