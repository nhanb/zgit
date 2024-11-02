const std = @import("std");
const httpz = @import("httpz");
const html = @import("./html.zig");
const db = @import("./db.zig");
const home = @import("./routes/home.zig");
const static = @import("./routes/static.zig");
const repo_commits = @import("./routes/repo_commits.zig");
const repo_commits_detail = @import("./routes/repo_commits_detail.zig");

const PORT = 8000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const is_initial_setup = try db.init();
    if (is_initial_setup) {
        std.debug.print("Initialized {s}\n", .{db.DB_PATH});
    } else {
        std.debug.print("Found existing {s}\n", .{db.DB_PATH});
    }

    // More advanced cases will use a custom "Handler" instead of "void".
    // The last parameter is our handler instance, since we have a "void"
    // handler, we passed a void ({}) value.
    var server = try httpz.Server(void).init(allocator, .{
        .port = PORT,
        // lots of other settings here - see httpz's README
    }, {});
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }

    var router = server.router(.{});
    router.get("/", home.serve, .{});
    router.get(static.URL_PATH ++ "/:filename", static.serve, .{});
    router.get("/:repo_name/commits/", repo_commits.serve, .{});
    router.get("/:repo_name/commits/:hash/", repo_commits_detail.serve, .{});
    std.debug.print("Started server at port {d}\n", .{PORT});

    // blocks
    try server.listen();
}
