const std = @import("std");
const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const db = @import("../db.zig");
const aprint = std.fmt.allocPrint;

pub fn serve(req: *httpz.Request, res: *httpz.Response) !void {
    const repo_name = req.param("repo_name").?;
    const hash = req.param("hash").?;

    const commit = db.getCommit(res.arena, repo_name, hash) catch |err| switch (err) {
        error.RepoNotFound, error.CommitHashNotFound => {
            res.status = 404;
            res.body = "Move along, nothing to see here.";
            return;
        },
        else => return err,
    };
    const h = html.Builder{ .allocator = res.arena };

    const body = templates.base(.{
        .builder = h,
        .title_tag_text = try aprint(res.arena, "commit {s} - {s}", .{ hash, repo_name }),
        .title = .{
            .elem = h.span(null, .{
                h.a(
                    .{ .href = "../../" },
                    .{repo_name},
                ),
                " » ",
                h.a(
                    .{ .href = "../" },
                    .{"commits"},
                ),
                " » ",
                hash,
            }),
        },
        .subtitle = commit.shortstat,
        .main = h.main(null, .{
            h.pre(null, .{
                commit.content,
            }),
        }),
    });

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
    res.status = 200;
}
