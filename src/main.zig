const std = @import("std");
const httpz = @import("httpz");
const html = @import("./html.zig");
const db = @import("./db.zig");
const home = @import("./routes/home.zig");
const register = @import("./routes/register.zig");
const static = @import("./routes/static.zig");

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
    var server = try httpz.Server(void).init(allocator, .{ .port = PORT }, {});
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }

    var router = server.router(.{});
    router.get("/", home.serve, .{});
    router.get("/register", register.serve, .{});
    router.get(static.URL_PATH ++ "/:filename", static.serve, .{});
    std.debug.print("Started server at port {d}\n", .{PORT});

    // blocks
    try server.listen();
}
