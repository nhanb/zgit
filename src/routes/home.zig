const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const std = @import("std");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    const arena = res.arena;
    res.status = 200;

    var config = db.Config{
        .site_name = .{},
        .tagline = .{},
    };
    try db.readConfig(&config);

    const h = html.Builder{ .allocator = arena };

    // TODO read repos from db

    // TODO construct repos table body

    const body = templates.base(.{
        .builder = h,
        .title = config.site_name.slice(),
        .subtitle = config.tagline.slice(),
        .main = h.main(null, .{
            h.link(.{ .rel = "stylesheet", .href = "/static/home.css" }),
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
    });

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
