const std = @import("std");
const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const time = @import("../time.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;

    var config = db.Config{};
    try db.readConfig(&config);

    const h = html.Builder{ .allocator = res.arena };

    // read repos from db then construct html table rows
    var repos = std.ArrayList(db.Repo).init(res.arena);
    try db.listRepos(res.arena, &repos);
    std.mem.sort(db.Repo, repos.items, {}, db.Repo.latestFirst);
    var repo_trs = std.ArrayList(html.Element).init(res.arena);
    for (0..repos.items.len) |i| {
        const name = repos.items[i].name.slice();

        var desc: []const u8 = repos.items[i].description.slice();
        if (desc.len == 0) {
            desc = "-";
        }

        const last_commit_ts = repos.items[i].last_commit_ts;
        const last_committed = switch (last_commit_ts) {
            0 => "-",
            else => try time.DateTime.initUnix(last_commit_ts).formatAlloc(
                res.arena,
                "YYYY-MM-DD HH:mm:ss z",
            ),
        };

        try repo_trs.append(h.tr(null, .{
            h.td(null, .{
                h.a(.{ .href = name }, .{name}),
            }),
            h.td(null, .{desc}),
            h.td(null, .{"TODO"}),
            h.td(null, .{last_committed}),
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
