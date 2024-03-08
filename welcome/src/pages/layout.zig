const std = @import("std");
const allocator = @import("../main.zig").allocator;
const window = @import("../main.zig").global_window;
const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("gio/gio.h");
    @cInclude("glib.h");
});

var first = true;

const layouts = struct {
    var code = std.ArrayList([]u8).init(allocator);
    var name = std.ArrayList([]u8).init(allocator);
};
const variants = struct {
    var code = std.ArrayList([]u8).init(allocator);
    var v_code = std.ArrayList([]u8).init(allocator);
    var name = std.ArrayList([]u8).init(allocator);
};

var layoutList: ?*c.GtkStringList = null;
var layoutLength: u32 = 0;
var layoutDD: ?*c.GtkWidget = null;
var languageDD: ?*c.GtkWidget = null;
var screenLayout: ?*c.GtkWidget = null;

pub fn page(_: bool) void {
    if (first) {
        first = false;
        layouts_set() catch @panic("Something is wrong with your xkb base.lsl");
    }

    const languageList = c.gtk_string_list_new(null);
    layoutList = c.gtk_string_list_new(null);
    c.gtk_string_list_append(layoutList, "Default");

    // I am too sleepy to get actually get the arraylist strings to convert nicely
    for (layouts.name.items) |x| {
        c.gtk_string_list_append(languageList, x.ptr);
    }
    languageDD = c.gtk_drop_down_new(@as(*c.GListModel, @ptrCast(languageList)), null);

    _ = c.g_signal_connect_data(languageDD, "notify::selected", @as(c.GCallback, @ptrCast(&struct {
        fn f(_: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
            c.gtk_string_list_splice(layoutList, 1, layoutLength, null);
            layoutLength = 0;
            const selected = layouts.code.items[c.gtk_drop_down_get_selected(@as(*c.GtkDropDown, @ptrCast(languageDD)))];
            for (variants.name.items, variants.code.items) |x, i| {
                if (std.mem.eql(u8, i, selected)) {
                    c.gtk_string_list_append(layoutList, x.ptr);
                    layoutLength += 1;
                }
            }
            window.pages.layout.languageSelected = @intCast(c.gtk_drop_down_get_selected(@as(*c.GtkDropDown, @ptrCast(languageDD))));
            c.gtk_drop_down_set_selected(@as(*c.GtkDropDown, @ptrCast(layoutDD)), 0);
        }
    }.f)), null, null, 0);

    layoutDD = c.gtk_drop_down_new(@as(*c.GListModel, @ptrCast(layoutList)), null);

    _ = c.g_signal_connect_data(layoutDD, "notify::selected", @as(c.GCallback, @ptrCast(&struct {
        fn f(_: *c.GtkApplication, _: c.gpointer) callconv(.C) void {
            const selectedLanguage = c.gtk_drop_down_get_selected(@as(*c.GtkDropDown, @ptrCast(languageDD)));
            const selectedVariant = c.gtk_drop_down_get_selected(@as(*c.GtkDropDown, @ptrCast(layoutDD)));
            if (selectedVariant == 0) {
                layout_update(layouts.code.items[selectedLanguage][0..2]);
            } else {
                const currentLanguage = layouts.code.items[selectedLanguage];
                var currentVariant: ?[]u8 = null;
                var index: usize = 0;
                for (variants.code.items, variants.v_code.items) |k, v| {
                    if (std.mem.eql(u8, k, currentLanguage)) {
                        if (index == selectedVariant - 1) {
                            currentVariant = v;
                            break;
                        }
                        index += 1;
                    }
                }
                var result = allocator.alloc(u8, currentLanguage.len + currentVariant.?.len) catch @panic("Failed to initilize string");
                defer allocator.free(result);

                std.mem.copyForwards(u8, result[0..], currentLanguage);
                result[currentLanguage.len - 1] = '+';
                std.mem.copyForwards(u8, result[currentLanguage.len..], currentVariant.?);
                layout_update(result);
            }
            window.pages.layout.variantSelected = @intCast(selectedVariant);
        }
    }.f)), null, null, 0);

    screenLayout = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_box_append(@as(*c.GtkBox, @ptrCast(screenLayout.?)), languageDD);
    c.gtk_box_append(@as(*c.GtkBox, @ptrCast(screenLayout.?)), layoutDD);

    const tmpSelected = window.pages.layout.variantSelected;

    if (window.pages.layout.languageSelected == -1) {
        for (layouts.code.items, 0..) |code, i| {
            if (std.mem.eql(u8, code[0..2], "us")) {
                c.gtk_drop_down_set_selected(@as(*c.GtkDropDown, @ptrCast(languageDD)), @intCast(i));
                break;
            }
        }
    } else {
        c.gtk_drop_down_set_selected(@as(*c.GtkDropDown, @ptrCast(languageDD)), @intCast(window.pages.layout.languageSelected));
    }

    c.gtk_drop_down_set_selected(@as(*c.GtkDropDown, @ptrCast(layoutDD)), @intCast(tmpSelected));

    c.gtk_window_set_child(@as(*c.GtkWindow, @ptrCast(window.window.?)), screenLayout);
    c.gtk_window_set_title(@as(*c.GtkWindow, @ptrCast(window.window.?)), "Select a keyboard layout");
}

fn layouts_set() !void {
    const file = try std.fs.openFileAbsolute("/usr/share/X11/xkb/rules/base.lst", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();

    const states = enum { BeforeLayout, Layout, AfterLayout, Variant, AfterVariant };
    var state: states = states.BeforeLayout;

    while (reader.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity();

        if (std.mem.eql(u8, line.items, "")) {
            if (state == states.Layout) {
                state = states.AfterLayout;
            } else if (state == states.Variant) {
                state = states.AfterVariant;
            }
        }

        var index: usize = 0;

        var current = std.ArrayList(u8).init(allocator);
        defer current.deinit();

        if (state == states.Layout) {
            while (line.items[index] == ' ') {
                index += 1;
            }
            while (line.items[index] != ' ') {
                try current.append(line.items[index]);
                index += 1;
            }

            try current.append(0);
            try layouts.code.append((try current.clone()).items);
            current.shrinkAndFree(0);

            while (line.items[index] == ' ') {
                index += 1;
            }
            while (line.items.len > index) {
                try current.append(line.items[index]);
                index += 1;
            }

            try current.append(0);
            try layouts.name.append((try current.clone()).items);
            current.shrinkAndFree(0);
        } else if (state == states.Variant) {
            while (line.items[index] == ' ') {
                index += 1;
            }
            while (line.items[index] != ' ') {
                try current.append(line.items[index]);
                index += 1;
            }

            try current.append(0);
            try variants.v_code.append((try current.clone()).items);
            current.shrinkAndFree(0);

            while (line.items[index] == ' ') {
                index += 1;
            }
            while (line.items[index] != ':') {
                try current.append(line.items[index]);
                index += 1;
            }
            index += 1;

            try current.append(0);
            try variants.code.append((try current.clone()).items);
            current.shrinkAndFree(0);

            while (line.items[index] == ' ') {
                index += 1;
            }
            while (line.items.len > index) {
                try current.append(line.items[index]);
                index += 1;
            }

            try current.append(0);
            try variants.name.append((try current.clone()).items);
            current.shrinkAndFree(0);
        }

        if (state == states.BeforeLayout and std.mem.eql(u8, line.items, "! layout")) {
            state = states.Layout;
        } else if (state == states.AfterLayout and std.mem.eql(u8, line.items, "! variant")) {
            state = states.Variant;
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    // Remove "custom"
    _ = layouts.name.pop();
    _ = layouts.code.pop();
}

fn layout_update(name: []const u8) void {
    const settings = c.g_settings_new("org.gnome.desktop.input-sources");
    _ = c.g_settings_set_value(settings, "sources", c.g_variant_new_array(c.g_variant_type_new("(ss)"), &[_]?*c.GVariant{c.g_variant_new_tuple(&[_]?*c.GVariant{ c.g_variant_new_string("xkb"), c.g_variant_new_string(@as([*c]const u8, @ptrCast(name))) }, 2)}, 1));
}
