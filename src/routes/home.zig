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

    // read repos from db then construct html table rows
    var repos = std.ArrayList(db.Repo).init(arena);
    try db.listRepos(&repos);
    var repo_trs = std.ArrayList(html.Element).init(arena);
    for (0..repos.items.len) |i| {
        const name = repos.items[i].name.slice();
        const desc = repos.items[i].description.slice();
        try repo_trs.append(h.tr(null, .{
            h.td(null, .{
                h.a(.{ .href = name }, .{name}),
            }),
            h.td(null, .{desc}),
            h.td(null, .{"TODO"}),
            h.td(null, .{"TODO"}),
        }));
    }

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
                h.tbody(null, .{
                    repo_trs.items,
                }),
            }),
        }),
    });

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
