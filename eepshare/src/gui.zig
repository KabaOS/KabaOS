const c = @import("main.zig").c;
const add_button_struct = @import("main.zig").add_button;
const allocator = @import("main.zig").allocator;
const server = @import("server.zig");
const std = @import("std");
const window = @import("main.zig").global_window;

const MARGIN = 16;
const MARGIN_LR = 6;

pub fn add_button(_: *c.GtkApplication, data: c.gpointer) callconv(.C) void {
    const real_data: *add_button_struct = @constCast(@ptrCast(&data));
    const file = c.gtk_file_chooser_dialog_new(
        "Select a file or folder",
        @ptrCast(window.window),
        real_data.gtk_type,
        "_Cancel",
        c.GTK_RESPONSE_CANCEL,
        "_Open",
        c.GTK_RESPONSE_ACCEPT,
        c.NULL,
    );

    c.gtk_window_present(@ptrCast(file));

    _ = c.g_signal_connect_data(
        file,
        "response",
        @ptrCast(&file_callback_add_button),
        null,
        null,
        0,
    );
}

pub fn file_callback_add_button(dialog: *c.GtkApplication, response: c_int) callconv(.C) void {
    if (response == c.GTK_RESPONSE_ACCEPT) {
        const file = c.g_file_get_path(c.gtk_file_chooser_get_file(@ptrCast(dialog)));
        const stat = std.fs.cwd().statFile(std.mem.span(file)) catch return;
        const file_type: server.share_type = switch (stat.kind) {
            .directory => .dir,
            .file => .file,
            else => return,
        };

        const stop = allocator.create(bool) catch return;
        stop.* = false;

        const row_s = create_new_hosting_row_file_callback(file, stop);

        _ = std.Thread.spawn(.{}, server.serve, .{
            server.options{ .share_type = file_type, .path = std.mem.span(file) },
            row_s.spinner,
            stop,
        }) catch return;

        c.gtk_box_append(@ptrCast(window.list_gtk), row_s.row);
    }

    c.gtk_window_destroy(@ptrCast(dialog));
}

const create_new_hosting_row_file_struct = struct {
    row: *c.GtkWidget,
    spinner: *c.GtkWidget,
};

pub fn create_new_hosting_row_file_callback(file: [*c]u8, stop: *bool) create_new_hosting_row_file_struct {
    const row = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, MARGIN);
    c.gtk_widget_set_margin_start(row, MARGIN_LR);
    c.gtk_widget_set_margin_end(row, MARGIN_LR);
    c.gtk_widget_set_margin_top(row, MARGIN / 2);

    const left = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, MARGIN);
    c.gtk_widget_set_hexpand(left, @intFromBool(true));
    c.gtk_widget_set_halign(left, c.GTK_ALIGN_START);
    c.gtk_box_append(@ptrCast(row), left);

    const spinner = c.gtk_spinner_new();
    c.gtk_box_append(@ptrCast(left), spinner);
    c.gtk_widget_set_margin_start(spinner, MARGIN - MARGIN_LR);
    c.gtk_widget_set_margin_end(spinner, MARGIN - MARGIN_LR);
    c.gtk_spinner_start(@ptrCast(spinner));

    const name = c.gtk_label_new(file);
    c.gtk_box_append(@ptrCast(left), name);
    c.gtk_label_set_ellipsize(@ptrCast(name), c.PANGO_ELLIPSIZE_END);
    c.gtk_widget_set_tooltip_text(name, file);

    const right = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, MARGIN);
    c.gtk_widget_set_hexpand(right, @intFromBool(true));
    c.gtk_widget_set_halign(right, c.GTK_ALIGN_END);
    c.gtk_box_append(@ptrCast(row), right);

    const delete_button = c.gtk_button_new_from_icon_name("window-close");
    c.gtk_widget_add_css_class(delete_button, "raised");
    c.gtk_box_append(@ptrCast(right), delete_button);

    const send = allocator.create(delete_hosting_row_struct) catch @panic("Ran out of mem");
    send.row = row;
    send.stop = stop;

    _ = c.g_signal_connect_data(
        delete_button,
        "clicked",
        @ptrCast(&delete_hosting_row),
        send,
        null,
        0,
    );

    return .{ .row = row, .spinner = spinner };
}

pub const delete_hosting_row_struct = struct {
    row: *c.GtkWidget,
    stop: *bool,
};

pub fn delete_hosting_row(_: *c.GtkWidget, i: *delete_hosting_row_struct) callconv(.C) void {
    c.gtk_box_remove(@ptrCast(window.list_gtk), i.row);
    i.stop.* = true;

    allocator.destroy(i);
}

pub fn loading_update(item: *c.GtkWidget, url: []u8) void {
    const button = c.gtk_button_new_from_icon_name("edit-copy");
    const spinner_parent = c.gtk_widget_get_parent(item);

    c.gtk_widget_insert_before(button, spinner_parent, item);
    c.gtk_box_remove(@ptrCast(spinner_parent), item);

    c.gtk_widget_add_css_class(button, "raised");
    c.gtk_widget_set_tooltip_text(button, @ptrCast(url));

    _ = c.g_signal_connect_data(
        button,
        "clicked",
        @ptrCast(&url_copy),
        @ptrCast(url),
        null,
        0,
    );
}

pub fn url_copy(_: *c.GtkWidget, url: *u8) callconv(.C) void {
    c.gdk_clipboard_set_text(c.gdk_display_get_clipboard(c.gdk_display_get_default()), url);
}
