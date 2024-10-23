const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const std = @import("std");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    const arena = res.arena;
    res.status = 200;

    var config = db.Config{
        .title = .{},
        .tagline = .{},
    };
    try db.readConfig(&config);

    const h = html.Builder{ .allocator = arena };
    const body = templates.base(
        arena,
        "Home",
        h.div(null, .{
            h.h1(null, .{config.title.slice()}),
            h.p(null, .{config.tagline.slice()}),
        }),
    );

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
