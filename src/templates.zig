const httpz = @import("httpz");
const html = @import("./html.zig");
const std = @import("std");

pub fn base(arena: std.mem.Allocator, title: []const u8, main_content: html.Element) html.Element {
    const h = html.Builder{ .allocator = arena };
    return h.html(
        .{ .lang = "en" },
        .{
            h.head(null, .{
                h.title(null, .{ title, " | zgit" }),
                h.link(.{ .rel = "stylesheet", .href = "/static/style.css" }),
                h.link(.{ .rel = "stylesheet", .href = "/static/register.css" }),
            }),
            h.body(null, .{
                main_content,
            }),
        },
    );
}
