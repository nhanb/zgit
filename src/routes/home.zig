const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const std = @import("std");
const time = @import("../time.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;

    var config = db.Config{};
    try db.readConfig(&config);

    const h = html.Builder{ .allocator = res.arena };

    // read repos from db then construct html table rows
    var repos = std.ArrayList(db.Repo).init(res.arena);
    try db.listRepos(res.arena, &repos);
    var repo_trs = std.ArrayList(html.Element).init(res.arena);
    for (0..repos.items.len) |i| {
        const name = repos.items[i].name.slice();
        var desc: []const u8 = repos.items[i].description.slice();
        if (desc.len == 0) {
            desc = "-";
        }

        const last_commit_time = time.DateTime.initUnix(repos.items[i].last_commit_ts);

        try repo_trs.append(h.tr(null, .{
            h.td(null, .{
                h.a(.{ .href = name }, .{name}),
            }),
            h.td(null, .{desc}),
            h.td(null, .{"TODO"}),
            h.td(null, .{try last_commit_time.formatAlloc(res.arena, "YYYY-MM-DD HH:mm:ss z")}),
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
                        h.th(null, .{"Last committed"}),
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
