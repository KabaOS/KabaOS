const window = @import("../main.zig").global_window;
const c = @cImport(@cInclude("gtk/gtk.h"));

pub fn finish(_: bool) void {
    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@as(*c.GtkBox, @ptrCast(box)), c.gtk_label_new("Thank you for using Kaba!"));
    c.gtk_window_set_child(@as(*c.GtkWindow, @ptrCast(window.window.?)), box);

    c.gtk_window_set_title(@as(*c.GtkWindow, @ptrCast(window.window.?)), "Thank You");
}
