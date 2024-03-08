const std = @import("std");
const page_update = @import("move.zig").page_update;
const c = @cImport(@cInclude("gtk/gtk.h"));

pub const allocator = std.heap.c_allocator;

pub const global_window = struct {
    pub var window: ?*c.GtkWidget = null;

    pub var back: ?*c.GtkWidget = null;
    pub var next: ?*c.GtkWidget = null;
    pub var finish: ?*c.GtkWidget = null;

    pub const functions = [_]*const fn (bool) void{
        @import("pages/welcome.zig").page,
        @import("pages/layout.zig").page,
        @import("pages/wifi.zig").page,
        @import("pages/finish.zig").page,
    };
    pub var index: usize = 0;

    pub const pages = struct {
        pub const layout = struct {
            pub var languageSelected: i16 = @intCast(-1);
            pub var variantSelected: i16 = @intCast(0);
        };
    };
};

pub fn main() !u8 {
    const app = c.gtk_application_new("com.github.arthurmelton.KabaOS.Welcome", c.G_APPLICATION_DEFAULT_FLAGS) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(app, "activate", @as(c.GCallback, @ptrCast(&welcome_new_main)), null, null, 0);
    const status = c.g_application_run(@as(*c.GApplication, @ptrCast(app)), 0, null);

    return @intCast(status);
}

fn welcome_new_main(app: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
    const back = c.gtk_button_new_from_icon_name("go-previous");
    c.gtk_widget_hide(back);
    c.gtk_widget_set_tooltip_text(back, "Back");
    _ = c.g_signal_connect_data(back, "clicked", @as(c.GCallback, @ptrCast(&struct {
        fn f(_: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
            page_update(false);
        }
    }.f)), null, null, 0);
    global_window.back = back;

    const next = c.gtk_button_new_from_icon_name("go-next");
    c.gtk_widget_set_tooltip_text(next, "Next");
    _ = c.g_signal_connect_data(next, "clicked", @as(c.GCallback, @ptrCast(&struct {
        fn f(_: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
            page_update(true);
        }
    }.f)), null, null, 0);
    global_window.next = next;

    const finish = c.gtk_button_new_with_label("Finish");
    c.gtk_widget_add_css_class(finish, "suggested-action");
    c.gtk_widget_hide(finish);
    _ = c.g_signal_connect_data(finish, "clicked", @as(c.GCallback, @ptrCast(&struct {
        fn f(_: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
            page_update(true);
        }
    }.f)), null, null, 0);
    global_window.finish = finish;

    const header = c.gtk_header_bar_new();
    c.gtk_header_bar_pack_start(@as(*c.GtkHeaderBar, @ptrCast(header)), back);
    c.gtk_header_bar_pack_end(@as(*c.GtkHeaderBar, @ptrCast(header)), next);
    c.gtk_header_bar_pack_end(@as(*c.GtkHeaderBar, @ptrCast(header)), finish);

    const window = c.gtk_application_window_new(app);
    c.gtk_widget_set_state_flags(window, c.GTK_DIALOG_MODAL, @as(u1, @bitCast(true)));
    c.gtk_window_set_deletable(@as(*c.GtkWindow, @ptrCast(window)), @as(u1, @bitCast(false)));
    c.gtk_window_set_resizable(@as(*c.GtkWindow, @ptrCast(window)), @as(u1, @bitCast(false)));
    c.gtk_window_set_default_size(@as(*c.GtkWindow, @ptrCast(window)), 400, 650);
    c.gtk_window_set_titlebar(@as(*c.GtkWindow, @ptrCast(window)), header);

    global_window.window = window;

    global_window.functions[global_window.index](true);

    c.gtk_widget_show(window);
}
