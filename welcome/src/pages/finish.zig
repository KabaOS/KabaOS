const c = @import("../main.zig").c;
const window = @import("../main.zig").global_window;

pub fn page(_: bool) void {
    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@ptrCast(box), c.gtk_label_new("Thank you for using Kaba!"));
    c.gtk_window_set_child(@ptrCast(window.window.?), box);

    c.gtk_window_set_title(@ptrCast(window.window.?), "Thank You");
}
