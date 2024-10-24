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

    // TODO read repos from db

    // TODO construct repos table body

    const body = templates.base(
        arena,
        "Home",
        h.div(null, .{
            h.link(.{ .rel = "stylesheet", .href = "/static/home.css" }),
            h.header(null, .{
                h.h1(.{ .id = "title" }, .{config.title.slice()}),
                h.p(.{ .id = "tagline" }, .{config.tagline.slice()}),
            }),
            h.main(null, .{
                h.table(.{ .id = "repos-table" }, .{
                    h.thead(null, .{
                        h.tr(null, .{
                            h.th(null, .{"Name"}),
                            h.th(null, .{"Description"}),
                            h.th(null, .{"Owner"}),
                            h.th(null, .{"Idle"}),
                        }),
                    }),
                }),
            }),
        }),
    );

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
