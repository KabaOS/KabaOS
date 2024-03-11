const window = @import("../main.zig").global_window;
const c = @cImport(@cInclude("gtk/gtk.h"));

pub fn page(_: bool) void {
    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@ptrCast(box), c.gtk_label_new("(Logo)"));
    c.gtk_box_append(@ptrCast(box), c.gtk_label_new("Thank you for using KabaOS!"));
    c.gtk_window_set_child(@ptrCast(window.window.?), box);

    c.gtk_window_set_title(@ptrCast(window.window.?), "Welcome");
}
