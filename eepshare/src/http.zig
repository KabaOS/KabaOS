const allocator = @import("main.zig").allocator;
const libsam3 = @cImport(@cInclude("libsam3.h"));
const server = @import("server.zig");
const std = @import("std");

const method = enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    OPITONS,
    TRACE,
    PATCH,
};

const request = struct {
    method: method,
    path: []const u8,
};

const header = struct { []const u8, []const u8 };

const parse_error = error{ NotAValidMethod, NoPath, FailedUnescape };

fn parse(data: *[server.read_length]u8) parse_error!request {
    const lines = @constCast(&std.mem.split(u8, data, "\n"));

    const first_line = @constCast(&std.mem.split(u8, lines.first(), " "));

    const _method = std.meta.stringToEnum(method, first_line.next() orelse return error.NotAValidMethod) orelse return error.NotAValidMethod;

    const _path = first_line.next() orelse return error.NoPath;

    const unescaped = std.Uri.unescapeString(allocator, _path) catch return error.FailedUnescape;

    return request{ .method = _method, .path = unescaped };
}

fn parse_deinit(_request: request) void {
    allocator.free(_request.path);
}

fn make_response(conn: *libsam3.Sam3Connection, code: u16, codestr: []const u8, headers: []const header, body: []u8) void {
    var header_length: usize = 0;
    for (0..headers.len) |i| {
        header_length += 2 + headers[i][0].len + 2 + headers[i][1].len;
    }

    var headersstr = allocator.alloc(u8, header_length) catch @panic("Failed to allocate room for headers");
    defer allocator.free(headersstr);

    var index: usize = 0;
    for (0..headers.len) |i| {
        headersstr[index] = '\r';
        index += 1;
        headersstr[index] = '\n';
        index += 1;
        std.mem.copyForwards(u8, headersstr[index..], headers[i][0]);
        index += headers[i][0].len;
        headersstr[index] = ':';
        index += 1;
        headersstr[index] = ' ';
        index += 1;
        std.mem.copyForwards(u8, headersstr[index..], headers[i][1]);
        index += headers[i][1].len;
    }

    const response = std.fmt.allocPrint(allocator, "HTTP/1.1 {d} {s}{s}\r\n\r\n{s}", .{ code, codestr, headersstr, body }) catch @panic("Failed to allocate room for header response");
    defer allocator.free(response);

    send(conn, response);
}

pub fn send(conn: *libsam3.Sam3Connection, data: []u8) void {
    if (libsam3.sam3tcpSend(conn.fd, @ptrCast(data), data.len) < 0) {
        std.log.err("Cant send to the user", .{});
    }
}

pub fn handle(conn: *libsam3.Sam3Connection, option: server.options, key: [52]u8) !void {
    defer _ = libsam3.sam3tcpDisconnect(conn.fd);
    errdefer make_response(conn, 500, "Internal Server Error", &[_]header{}, "");

    var cmd: [server.read_length]u8 = undefined;

    if (libsam3.sam3tcpReceiveEx(conn.fd, &cmd, cmd.len, 1) < 0) {
        std.log.err("Cant read from the user", .{});
    }

    const parsed = parse(&cmd) catch return make_response(conn, 400, "Bad Request", &[_]header{}, "");
    defer parse_deinit(parsed);

    std.log.info("Request {s}.b32.i2p - {s} {s}", .{ key, @tagName(parsed.method), parsed.path });

    var path: []u8 = undefined;
    var path_defer = false;

    if (option.share_type == .file) {
        if (!std.mem.eql(u8, "/", parsed.path)) return make_response(conn, 404, "Not Found", &[_]header{}, "");
        path = option.path;
    } else {
        if (std.mem.containsAtLeast(u8, parsed.path, 1, "..")) return make_response(conn, 400, "Bad Request", &[_]header{}, "");
        var file_name = try allocator.alloc(u8, option.path.len + parsed.path.len);

        std.mem.copyForwards(u8, file_name, option.path);
        std.mem.copyForwards(u8, file_name[option.path.len..], parsed.path);

        path_defer = true;
        path = file_name;
    }
    var file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    defer {
        if (path_defer) {
            allocator.free(path);
        }
    }

    const file_stats = file.stat() catch return;

    if (file_stats.kind == .directory) {
        var directory = try std.fs.openDirAbsolute(path, .{ .iterate = true });
        var it = directory.iterate();

        var html = std.ArrayList(u8).init(allocator);
        defer html.deinit();
        try html.appendSlice("<!DOCTYPE html><html><head><title>Eepshare</title></head><body>");

        try html.appendSlice("<a href=\"../\"><pre>parent</pre></a><br>");

        while (try it.next()) |_file| {
            try html.appendSlice("<a href=\"");
            try html.appendSlice(parsed.path);
            try html.appendSlice(_file.name);
            if (_file.kind == .directory) {
                try html.append('/');
            }
            try html.appendSlice("\"><pre>");
            try html.appendSlice(_file.name);
            if (_file.kind == .directory) {
                try html.append('/');
            }
            try html.appendSlice("</pre></a>");
        }
        try html.appendSlice("</body></html>");

        const size_str = try size_int_from_handle(html.items.len);
        defer allocator.free(size_str);

        make_response(conn, 200, "OK", &[_]header{ .{ "Content-Type", "text/html" }, .{ "Content-Length", size_str } }, html.items);
    } else {
        var buffered: [2 ^ 15]u8 = undefined;

        const size_str = try size_int_from_handle(file_stats.size);
        defer allocator.free(size_str);

        var made_header = false;

        const content_disposition_before = "attachment; filename=\"";
        const file_name = std.fs.path.basenamePosix(path);

        const content_disposition = try allocator.alloc(u8, content_disposition_before.len + file_name.len + 1);
        defer allocator.free(content_disposition);

        std.mem.copyForwards(u8, content_disposition, content_disposition_before);
        std.mem.copyForwards(u8, content_disposition[content_disposition_before.len..], file_name);
        content_disposition[content_disposition.len - 1] = '"';

        while (try file.read(&buffered) > 0) {
            if (!made_header) {
                make_response(conn, 200, "OK", &[_]header{ .{ "Content-Type", "application/octet-stream" }, .{ "Content-Length", size_str }, .{ "Content-Disposition", content_disposition } }, "");
                made_header = true;
            }

            send(conn, &buffered);
        }
    }
}

fn size_int_from_handle(size: u64) ![]u8 {
    var int_size: u8 = 1;
    var tmp_size = size;
    while (tmp_size > 9) {
        tmp_size /= 10;
        int_size += 1;
    }

    var size_str = try allocator.alloc(u8, int_size);

    tmp_size = size;
    for (0..int_size) |i| {
        size_str[int_size - i - 1] = @intCast(tmp_size % 10 + 48);
        tmp_size /= 10;
    }

    return size_str;
}
