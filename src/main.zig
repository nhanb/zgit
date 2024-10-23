const std = @import("std");
const httpz = @import("httpz");
const zqlite = @import("zqlite");
const html = @import("./html.zig");
const serveHome = @import("./routes/home.zig").serve;
const serveRegister = @import("./routes/register.zig").serve;
const static = @import("./routes/static.zig");

const DB_PATH = "workdir/zgit.db";
const PORT = 8000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try initDb(DB_PATH);
    std.debug.print("Initialized {s}\n", .{DB_PATH});

    // More advance cases will use a custom "Handler" instead of "void".
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
    router.get("/static/register.css", static.serveRegisterCss, .{});
    std.debug.print("Started server at port {d}\n", .{PORT});

    // blocks
    try server.listen();
}

fn initDb(db_path: [:0]const u8) !void {
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(db_path, flags);
    defer conn.close();

    try conn.execNoArgs(
        \\create table users (
        \\    id integer primary key,
        \\    username text unique not null
        \\);
    );

    try conn.execNoArgs(
        \\create table repo (
        \\    id integer primary key,
        \\    name text unique not null,
        \\    created_at text default current_timestamp,
        \\    created_by integer not null,
        \\
        \\    foreign key (created_by) references users (id)
        \\);
    );

    try conn.execNoArgs(
        \\create table user_repo_access (
        \\    user_id integer not null,
        \\    repo_id integer not null,
        \\    can_read boolean not null,
        \\    can_write boolean not null,
        \\
        \\    foreign key (user_id) references users (id),
        \\    foreign key (repo_id) references repo (id)
        \\);
    );
}
