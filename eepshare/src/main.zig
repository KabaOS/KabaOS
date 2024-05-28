const gui = @import("gui.zig");
const server = @import("server.zig");
const std = @import("std");

pub const allocator = std.heap.c_allocator;
pub const c = @cImport({
    @cInclude("adwaita.h");
    @cInclude("gtk/gtk.h");
    @cInclude("libsam3.h");
});

pub const global_window = struct {
    pub var window: *c.GtkWidget = undefined;

    pub var list_gtk: *c.GtkWidget = undefined;
};

pub const std_options = .{
    .log_level = .info,
};

pub const add_button = struct {
    gtk_type: c_uint,
    share_type: server.share_type,
};

pub fn main() !u8 {
    const app = c.adw_application_new(
        "com.github.arthurmelton.KabaOS.eepshare",
        c.G_APPLICATION_DEFAULT_FLAGS,
    ) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(app, "activate", @ptrCast(&eepshare_new_main), null, null, 0);
    const status = c.g_application_run(@ptrCast(app), 0, null);

    return @intCast(status);
}

fn eepshare_new_main(app: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
    const header = c.adw_header_bar_new();

    const new_button = c.gtk_button_new_from_icon_name("list-add");
    c.gtk_widget_add_css_class(new_button, "raised");
    _ = c.g_signal_connect_data(
        new_button,
        "clicked",
        @ptrCast(&gui.add_button),
        @constCast(&add_button{
            .gtk_type = c.GTK_FILE_CHOOSER_ACTION_OPEN,
            .share_type = .file,
        }),
        null,
        0,
    );

    c.adw_header_bar_pack_start(@ptrCast(header), new_button);

    const window = c.gtk_application_window_new(app);
    c.gtk_widget_set_state_flags(window, c.GTK_DIALOG_MODAL, @as(u1, @bitCast(true)));
    c.gtk_window_set_resizable(@ptrCast(window), @as(u1, @bitCast(false)));
    c.gtk_window_set_default_size(@ptrCast(window), 400, 650);
    c.gtk_window_set_titlebar(@ptrCast(window), header);

    global_window.window = window;

    const list_gtk = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_widget_add_css_class(list_gtk, "boxed-list-separate");

    global_window.list_gtk = list_gtk;

    c.gtk_widget_show(window);
    c.gtk_window_set_child(@ptrCast(global_window.window), global_window.list_gtk);
}
