const std = @import("std");
const window = @import("main.zig").global_window;
const c = @cImport(@cInclude("gtk/gtk.h"));

pub fn page_update(forward: bool) void {
    if (forward) {
        window.index += 1;
    } else {
        window.index -= 1;
    }

    if (window.index == window.functions.len) {
        std.os.exit(0);
    }

    if (window.index > 0) {
        c.gtk_widget_show(window.back);
    } else {
        c.gtk_widget_hide(window.back);
    }

    if (window.index < window.functions.len - 1) {
        c.gtk_widget_show(window.next);
        c.gtk_widget_hide(window.finish);
    } else {
        c.gtk_widget_hide(window.next);
        c.gtk_widget_show(window.finish);
    }

    window.functions[window.index](forward);
}
