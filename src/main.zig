const std = @import("std");
const httpz = @import("httpz");
const html = @import("./html.zig");
const db = @import("./db.zig");
const serveHome = @import("./routes/home.zig").serve;
const serveRegister = @import("./routes/register.zig").serve;
const static = @import("./routes/static.zig");

const PORT = 8000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try db.init();
    std.debug.print("Initialized {s}\n", .{db.DB_PATH});

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
    router.get("/", serveHome, .{});
    router.get("/register", serveRegister, .{});
    router.get("/static/style.css", static.serveStyleCss, .{});
    router.get("/static/home.css", static.serveHomeCss, .{});
    router.get("/static/register.css", static.serveRegisterCss, .{});
    std.debug.print("Started server at port {d}\n", .{PORT});

    // blocks
    try server.listen();
}
