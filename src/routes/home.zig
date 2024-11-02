const std = @import("std");
const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const time = @import("../time.zig");
const static = @import("./static.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;

    var config = db.Config{};
    try db.readConfig(&config);

    const h = html.Builder{ .allocator = res.arena };

    // read repos from db then construct html table rows
    var repos = try db.listRepos(res.arena);
    std.mem.sort(db.Repo, repos.items, {}, db.Repo.latestFirst);
    var repo_trs = std.ArrayList(html.Element).init(res.arena);
    for (0..repos.items.len) |i| {
        const name = repos.items[i].name.slice();

        var desc: []const u8 = repos.items[i].description.slice();
        if (desc.len == 0) {
            desc = "-";
        }

        var last_committed = repos.items[i].last_committed;
        if (last_committed.len == 0) {
            last_committed = "-";
        }

        var num_commits = repos.items[i].num_commits;
        if (num_commits.len == 0) {
            num_commits = "-";
        }

        try repo_trs.append(h.tr(null, .{
            h.td(null, .{
                h.a(.{ .href = try std.fmt.allocPrint(res.arena, "{s}/", .{name}) }, .{
                    name,
                }),
            }),
            h.td(null, .{desc}),
            h.td(null, .{"TODO"}),
            h.td(null, .{num_commits}),
            h.td(null, .{last_committed}),
        }));
    }

    const title = config.site_name.slice();
    const body = templates.base(.{
        .builder = h,
        .title_tag_text = title,
        .title = .{ .text = title },
        .subtitle = config.tagline.slice(),
        .main = h.main(null, .{
            h.link(.{ .rel = "stylesheet", .href = static.home_css.url_path }),
            h.table(.{ .id = "repos-table" }, .{
                h.thead(null, .{
                    h.tr(null, .{
                        h.th(null, .{"Name"}),
                        h.th(null, .{"Description"}),
                        h.th(null, .{"Owner"}),
                        h.th(null, .{"Commits"}),
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
