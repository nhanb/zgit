const std = @import("std");
const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const aprint = std.fmt.allocPrint;

pub fn serve(req: *httpz.Request, res: *httpz.Response) !void {
    const repo_name = req.param("repo_name").?;

    const repo = db.getRepo(res.arena, repo_name) catch |err| switch (err) {
        error.RepoNotFound => {
            res.status = 404;
            res.body = "Move along, nothing to see here.";
            return;
        },
        else => return err,
    };
    const h = html.Builder{ .allocator = res.arena };

    var commit_rows = std.ArrayList(html.Element).init(res.arena);
    for (repo.commits) |commit| {
        try commit_rows.append(h.tr(null, .{
            h.td(null, .{
                h.a(.{ .href = try aprint(res.arena, "{s}/", .{commit.hash_long}) }, .{
                    commit.hash_short,
                }),
            }),
            h.td(null, .{commit.title}),
            h.td(null, .{ commit.author_name, " <", commit.author_email, ">" }),
            h.td(null, .{commit.datetime}),
        }));
    }

    const body = templates.base(.{
        .builder = h,
        .title_tag_text = repo.name,
        .title = .{
            .elem = h.span(null, .{
                h.a(
                    .{ .href = "../" },
                    .{repo_name},
                ),
                " » commits",
            }),
        },
        .subtitle = try aprint(res.arena, "{d} commits so far", .{repo.commits.len}),
        .main = h.main(null, .{
            h.table(null, .{
                h.thead(null, .{
                    h.tr(null, .{
                        h.td(null, .{"Hash"}),
                        h.td(null, .{"Title"}),
                        h.td(null, .{"Author"}),
                        h.td(null, .{"Date"}),
                    }),
                }),
                h.tbody(null, .{
                    commit_rows.items,
                }),
            }),
        }),
    });

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
    res.status = 200;
}
